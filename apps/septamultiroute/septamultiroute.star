"""
Applet: SEPTA Transit
Summary: SEPTA Transit Departures
Description: Displays departure times for SEPTA buses, trolleys, and MFL/BSL in and around Philadelphia.
Author: radiocolin
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

API_V2 = "https://www3.septa.org/api/v2"
API_V1 = "https://www3.septa.org/api"
API_FLAT = "https://flat-api.septa.org"

DEFAULT_ROUTE = "17"
DEFAULT_STOP = "10264"
DEFAULT_BANNER = ""

def call_routes_api():
    cached = cache.get("routes_v2")
    if cached != None:
        return sort_routes(json.decode(cached))

    # Try v2 first
    r = http.get(API_V2 + "/routes/")
    routes = []
    if r.status_code == 200:
        routes = r.json()

    if len(routes) > 0:
        cache.set("routes_v2", json.encode(routes), ttl_seconds = 604800)
        return sort_routes(routes)

    # Fallback to v1 if v2 fails or is empty — do not cache so v2 is retried next render
    r = http.get(API_V1 + "/Routes/")
    if r.status_code == 200:
        routes = r.json()
    return sort_routes(routes)

def sort_routes(routes):
    numerical_routes = []
    non_numerical_routes = []

    for route in routes:
        name = route["route_short_name"]
        if name.isdigit():
            numerical_routes.append(route)
        else:
            non_numerical_routes.append(route)

    numerical_routes = sorted(numerical_routes, key = lambda x: int(x["route_short_name"]))
    return numerical_routes + non_numerical_routes

def get_routes():
    routes = call_routes_api()
    list_of_routes = []

    for i in routes:
        # 0: Tram/Trolley, 1: Subway, 3: Bus (GTFS types)
        # 2 is Rail, which we often exclude or handle differently
        if i["route_type"] != 2:
            list_of_routes.append(
                schema.Option(
                    display = i["route_short_name"] + ": " + i["route_long_name"],
                    value = i["route_id"],
                ),
            )

    if not list_of_routes:
        return [schema.Option(display = "17: South Philly to Center City", value = "17")]

    return list_of_routes

def get_route_info(route_id):
    routes = call_routes_api()
    for i in routes:
        if i["route_id"] == route_id:
            return i
    return None

def fetch_stops(route_id):
    cache_key = "stops_v2_" + route_id
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    url = "%s/stops/%s/stops.json" % (API_FLAT, route_id)
    r = http.get(url)
    stops = r.json() if r.status_code == 200 else []

    if len(stops) > 0:
        cache.set(cache_key, json.encode(stops), ttl_seconds = 604800)
    return stops

def sort_stops_geographically(stops):
    if len(stops) <= 1:
        return stops
    lats = [float(s["stop_lat"]) for s in stops]
    lngs = [float(s["stop_lon"]) for s in stops]
    if max(lngs) - min(lngs) > max(lats) - min(lats):
        return sorted(stops, key = lambda s: float(s["stop_lon"]))
    else:
        return sorted(stops, key = lambda s: float(s["stop_lat"]))

def direction_destinations(stops):
    endpoints = {}
    for s in stops:
        direction = str(int(s["direction_id"]))
        sequence = int(s["stop_sequence"])
        endpoint = endpoints.get(direction)
        if endpoint == None or sequence > endpoint["sequence"]:
            endpoints[direction] = {
                "sequence": sequence,
                "name": s["stop_name"],
            }

    destinations = {}
    for direction, endpoint in endpoints.items():
        name = endpoint["name"].replace("&amp;", "&")
        name = name.replace(" - Drop-off Only", "")
        name = name.replace(" - MBNS", "")
        destinations[direction] = name
    return destinations

def get_stops(route_id):
    stops = sort_stops_geographically(fetch_stops(route_id))
    destinations = direction_destinations(stops)
    seen = {}
    options = []
    for i in stops:
        stop_id_int = int(i["stop_id"])
        key = "%s_%s" % (stop_id_int, int(i["direction_id"]))
        destination = destinations.get(str(int(i["direction_id"])), "")
        display_name = i["stop_name"].replace("&amp;", "&")
        if destination:
            display_name += " (To " + destination + ")"
        display_name += " [" + str(stop_id_int) + "]"

        # Sometimes a stop is listed multiple times for different patterns
        if seen.get(key):
            continue
        seen[key] = True

        options.append(
            schema.Option(
                display = display_name,
                value = str(stop_id_int),
            ),
        )
    return options

def parse_time_to_seconds(t_str):
    parts = t_str.split(":")
    h = int(parts[0])
    m = int(parts[1])
    s = int(parts[2])
    return h * 3600 + m * 60 + s

def parse_release_date(release_name):
    if len(release_name) != 8 or not release_name.isdigit():
        return None
    return release_name

def select_schedule_release(full_schedule, now):
    today = now.format("20060102")
    dated_releases = []

    for s in full_schedule:
        release_name = parse_release_date(s.get("release_name", ""))
        if release_name == None:
            continue
        if release_name not in dated_releases:
            dated_releases.append(release_name)

    if not dated_releases:
        return None

    eligible = [release_name for release_name in dated_releases if release_name <= today]
    if eligible:
        return max(eligible)

    return max(dated_releases)

def call_schedule_api(route, stopid):
    cache_key = "sched_v2_%s_%s" % (route, stopid)

    # Cache schedule for 1 hour to allow for service changes
    # Real-time trips will be fetched fresh every time
    cached_sched = cache.get(cache_key)
    if cached_sched != None:
        full_schedule = json.decode(cached_sched)
    else:
        sched_url = "%s/schedules/stops/%s/%s/schedule.json" % (API_FLAT, route, stopid)
        r_sched = http.get(sched_url)
        full_schedule = r_sched.json() if r_sched.status_code == 200 else []
        if len(full_schedule) > 0:
            cache.set(cache_key, json.encode(full_schedule), ttl_seconds = 3600)

    if not full_schedule:
        return []

    # Fetch live trips for real-time delays
    live_data = {}

    # Try v2 first
    r_trips = http.get("%s/trips/?route_id=%s" % (API_V2, route))
    if r_trips.status_code == 200:
        for t in r_trips.json():
            live_data[t["trip_id"]] = t

    # Fallback to v1 if v2 yields nothing
    if not live_data:
        r_v1 = http.get("%s/TransitView/index.php" % API_V1, params = {"route": route})
        if r_v1.status_code == 200:
            v1_data = r_v1.json()
            for b in v1_data.get("bus", []):
                # Map v1 fields to v2 format for consistency
                tid = b.get("trip")
                if tid:
                    live_data[tid] = {
                        "trip_id": tid,
                        "delay": b.get("late", 0),
                        "next_stop_sequence": b.get("next_stop_sequence"),
                        "status": "LATE" if int(b.get("late", 0)) > 2 else "ON-TIME",
                    }

    now = time.now().in_location("America/New_York")
    now_secs = parse_time_to_seconds(now.format("15:04:05"))
    selected_release = select_schedule_release(full_schedule, now)

    filtered_schedule = full_schedule
    if selected_release != None:
        filtered_schedule = [s for s in full_schedule if s.get("release_name", "") == selected_release]

    service_id_counts = {}

    # Infer today's service_id from live trips
    for s in filtered_schedule:
        if str(s["trip_id"]) in live_data:
            svc_id = s["service_id"]
            service_id_counts[svc_id] = service_id_counts.get(svc_id, 0) + 1

    today_service_id = None
    max_count = 0
    for svc_id, count in service_id_counts.items():
        if count > max_count:
            max_count = count
            today_service_id = svc_id

    # Fallback guess for service_id based on day of week
    if not today_service_id:
        # If we can't infer it from live data, we'll look for the most frequent
        # service_id in the schedule. This is safer than hardcoding 10/12/13.
        counts = {}
        for s in filtered_schedule:
            sid = s["service_id"]
            counts[sid] = counts.get(sid, 0) + 1

        best_sid = None
        max_sid_count = 0
        for sid, count in counts.items():
            if count > max_sid_count:
                max_sid_count = count
                best_sid = sid
        today_service_id = best_sid

    unique_trips = {}
    for s in filtered_schedule:
        if s["service_id"] != today_service_id:
            continue

        # A single release should already be canonical, but keep trip_id-based
        # dedupe in case SEPTA repeats the same trip within that release.
        tid = str(s["trip_id"])
        if tid not in unique_trips:
            unique_trips[tid] = s

    results = []
    for s in unique_trips.values():
        trip_id = str(s["trip_id"])
        sched_secs = parse_time_to_seconds(s["arrival_time"])
        delay = 0
        is_live = False
        live = None

        if trip_id in live_data:
            live = live_data[trip_id]

            # Use live data only if it has GPS and sane delay
            # SEPTA sometimes sends "998" or other bogus delay for "NO GPS"
            if live.get("status") != "NO GPS" and live.get("delay") != None and abs(float(live["delay"])) < 120:
                # Skip if it already passed our stop according to sequence
                if live.get("next_stop_sequence") != None:
                    if int(live["next_stop_sequence"]) > int(s["stop_sequence"]):
                        continue
                delay = int(float(live["delay"]) * 60)
                is_live = True

        eta_secs = sched_secs + delay - now_secs

        # Filter out trips in the past (allow 2 min buffer for late arrivals)
        # However, for the canonical schedule, we MUST show future scheduled trips
        # regardless of live data filtering.
        if eta_secs < -120:
            continue

        stops_away = None
        if is_live and live.get("next_stop_sequence") != None:
            stops_away = int(s["stop_sequence"]) - int(live["next_stop_sequence"])

        results.append({
            "eta_secs": eta_secs,
            "scheduled": s["arrival_time"],
            "headsign": s["trip_headsign"],
            "is_live": is_live,
            "delay_mins": int(delay / 60),
            "stops_away": stops_away,
        })

    # Sort by ETA
    return sorted(results, key = lambda x: x["eta_secs"])[:10]

def get_schedule(route, stopid, show_relative_times, scale):
    departures = call_schedule_api(route, stopid)

    # 1. Pre-process to find max width needed for the time column
    processed_deps = []
    max_chars = 0
    for dep in departures:
        if show_relative_times:
            mins = int(dep["eta_secs"] / 60)
            t_str = "Now" if mins <= 0 else str(mins) + "m"
        else:
            parts = dep["scheduled"].split(":")
            h = int(parts[0])
            m = parts[1]
            suffix = "a"
            if h >= 24:
                h -= 24
            if h >= 12:
                suffix = "p"
                if h > 12:
                    h -= 12
            if h == 0:
                h = 12
            t_str = str(h) + ":" + m + suffix

        if len(t_str) > max_chars:
            max_chars = len(t_str)
        processed_deps.append((dep, t_str))

    # tom-thumb font is roughly 4px wide per character (3px glyph + 1px spacing)
    # terminus-12 is roughly 6px wide
    char_width = 4 if scale == 1 else 6
    time_col_width = max_chars * char_width + 1
    if time_col_width < 12 * scale:
        time_col_width = 12 * scale

    list_of_departures = []
    for i, (dep, t_str) in enumerate(processed_deps):
        background = "#222" if i % 2 == 1 else "#000"
        text = "#fff" if i % 2 == 1 else "#ffc72c"

        # Live indicator color coding: Red if > 5m late, Green otherwise
        if dep["is_live"]:
            time_color = "#f00" if dep["delay_mins"] > 5 else "#0f0"
        else:
            time_color = text

        headsign = dep["headsign"]
        if dep.get("stops_away") != None:
            if dep["stops_away"] <= 0:
                headsign += " - Approaching"
            elif dep["stops_away"] == 1:
                headsign += " - 1 stop away"
            else:
                headsign += " - %d stops away" % dep["stops_away"]

        row_font = "tom-thumb" if scale == 1 else "terminus-12"
        row_height = 6 * scale

        item = render.Box(
            height = row_height,
            width = 64 * scale,
            color = background,
            child = render.Row(
                children = [
                    render.Box(
                        width = time_col_width,
                        child = render.Padding(
                            pad = (0, 0, 1 * scale, 0),  # Small gap before marquee
                            child = render.Text(
                                content = t_str,
                                font = row_font,
                                color = time_color,
                            ),
                        ),
                    ),
                    render.Marquee(
                        child = render.Text(
                            headsign,
                            font = row_font,
                            color = text,
                        ),
                        width = 64 * scale - time_col_width,
                        offset_start = 40 * scale,
                        offset_end = 40 * scale,
                    ),
                ],
            ),
        )
        list_of_departures.append(item)

    if len(list_of_departures) < 1:
        msg = "No departures" if stopid else "Select a stop"
        return [render.Box(
            height = 6 * scale,
            width = 64 * scale,
            color = "#000",
            child = render.Text(msg, font = "tom-thumb" if scale == 1 else "tb-8"),
        )]
    else:
        return list_of_departures

def select_stop_for(stop_id, route):
    options = get_stops(route)
    stop_names = {
        "stop1": "Route 1 Stop",
        "stop2": "Route 2 Stop",
        "stop3": "Route 3 Stop",
        "stop4": "Route 4 Stop",
    }
    stop_name = stop_names.get(stop_id, "Stop")
    if not options:
        return [schema.Text(id = stop_id, name = stop_name, desc = "No stops found", default = "")]
    return [
        schema.Dropdown(
            id = stop_id,
            name = stop_name,
            desc = "Select a stop and direction.",
            icon = "bus",
            default = options[0].value,
            options = options,
        ),
    ]

def select_stop_1(route):
    return select_stop_for("stop1", route)

def select_stop_2(route):
    return select_stop_for("stop2", route)

def select_stop_3(route):
    return select_stop_for("stop3", route)

def select_stop_4(route):
    return select_stop_for("stop4", route)

def eta_label(departure):
    parts = departure["scheduled"].split(":")
    total_minutes = int(parts[0]) * 60 + int(parts[1]) + departure["delay_mins"]
    hour = (total_minutes // 60) % 24
    minute = total_minutes % 60
    display_hour = hour % 12
    if display_hour == 0:
        display_hour = 12
    minute_text = str(minute)
    if minute < 10:
        minute_text = "0" + minute_text
    return str(display_hour) + ":" + minute_text

def compact_route_row(route, stop, scale, row_height):
    departures = call_schedule_api(route, stop)[:2] if stop else []
    arrival_text = "--"
    if departures:
        arrival_text = "  ".join([eta_label(dep) for dep in departures])

    route_info = get_route_info(route)
    route_bg_color = "#000000"
    route_text_color = "#ffffff"
    if route_info:
        route_bg_color = "#" + route_info["route_color"]
        route_text_color = "#" + route_info["route_text_color"]

    font = "tom-thumb" if scale == 1 else "terminus-12"
    text_height = 6 * scale
    top_pad = (row_height - text_height) // 2
    if top_pad < 0:
        top_pad = 0

    return render.Box(
        width = 64 * scale,
        height = row_height,
        color = "#000000",
        child = render.Row(
            children = [
                render.Box(
                    width = 14 * scale,
                    height = row_height,
                    color = route_bg_color,
                    child = render.Padding(
                        pad = (1 * scale, top_pad, 0, 0),
                        child = render.Text(route, font = font, color = route_text_color),
                    ),
                ),
                render.Padding(
                    pad = (2 * scale, top_pad, 0, 0),
                    child = render.Text(arrival_text, font = font, color = "#ffffff"),
                ),
            ],
        ),
    )

def main(config):
    scale = 2 if canvas.is2x() else 1
    selected = [(config.str("route1", DEFAULT_ROUTE), config.str("stop1", DEFAULT_STOP))]

    if config.bool("enable2", False):
        selected.append((config.str("route2", DEFAULT_ROUTE), config.str("stop2", "")))
    if config.bool("enable3", False):
        selected.append((config.str("route3", DEFAULT_ROUTE), config.str("stop3", "")))
    if config.bool("enable4", False):
        selected.append((config.str("route4", DEFAULT_ROUTE), config.str("stop4", "")))

    row_height = (32 * scale) // len(selected)
    rows = [compact_route_row(route, stop, scale, row_height) for route, stop in selected]

    return render.Root(
        delay = 100,
        max_age = 180,
        child = render.Column(children = rows),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "route1",
                name = "Route 1",
                desc = "Select the first route.",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop1",
                source = "route1",
                handler = select_stop_1,
            ),
            schema.Toggle(
                id = "enable2",
                name = "Show route 2",
                desc = "Enable the second route.",
                icon = "bus",
                default = False,
            ),
            schema.Dropdown(
                id = "route2",
                name = "Route 2",
                desc = "Select the second route.",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop2",
                source = "route2",
                handler = select_stop_2,
            ),
            schema.Toggle(
                id = "enable3",
                name = "Show route 3",
                desc = "Enable the third route.",
                icon = "bus",
                default = False,
            ),
            schema.Dropdown(
                id = "route3",
                name = "Route 3",
                desc = "Select the third route.",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop3",
                source = "route3",
                handler = select_stop_3,
            ),
            schema.Toggle(
                id = "enable4",
                name = "Show route 4",
                desc = "Enable the fourth route.",
                icon = "bus",
                default = False,
            ),
            schema.Dropdown(
                id = "route4",
                name = "Route 4",
                desc = "Select the fourth route.",
                icon = "signsPost",
                default = DEFAULT_ROUTE,
                options = get_routes(),
            ),
            schema.Generated(
                id = "stop4",
                source = "route4",
                handler = select_stop_4,
            ),
        ],
    )
