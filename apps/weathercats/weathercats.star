load("cache.star", "cache")
load("christmas-v2.png", christmas_file = "file")
load("christmas-v2@2x.png", christmas_2x_file = "file")
load("cinco-de-mayo-v2.png", cinco_file = "file")
load("cinco-de-mayo-v2@2x.png", cinco_2x_file = "file")
load("clear-night-v2.png", clear_night_file = "file")
load("clear-night-v2@2x.png", clear_night_2x_file = "file")
load("cloudy-v2.png", cloudy_file = "file")
load("cloudy-v2@2x.png", cloudy_2x_file = "file")
load("cold-v2.png", cold_file = "file")
load("cold-v2@2x.png", cold_2x_file = "file")
load("encoding/json.star", "json")
load("halloween-v2.png", halloween_file = "file")
load("halloween-v2@2x.png", halloween_2x_file = "file")
load("hot-v2.png", hot_file = "file")
load("hot-v2@2x.png", hot_2x_file = "file")
load("http.star", "http")
load("humanize.star", "humanize")
load("july-4th-v2.png", july_fourth_file = "file")
load("july-4th-v2@2x.png", july_fourth_2x_file = "file")
load("new-years-v2.png", new_years_file = "file")
load("new-years-v2@2x.png", new_years_2x_file = "file")
load("oedi-fall.png", oedi_fall_file = "file")
load("oedi-fall@2x.png", oedi_fall_2x_file = "file")
load("oedi-spring.png", oedi_spring_file = "file")
load("oedi-spring@2x.png", oedi_spring_2x_file = "file")
load("oedi-summer.png", oedi_summer_file = "file")
load("oedi-summer@2x.png", oedi_summer_2x_file = "file")
load("oedi-winter.png", oedi_winter_file = "file")
load("oedi-winter@2x.png", oedi_winter_2x_file = "file")
load("rain-v2.png", rain_file = "file")
load("rain-v2@2x.png", rain_2x_file = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("snow-v2.png", snow_file = "file")
load("snow-v2@2x.png", snow_2x_file = "file")
load("st-patricks-day-v2.png", st_patricks_file = "file")
load("st-patricks-day-v2@2x.png", st_patricks_2x_file = "file")
load("storm-v2.png", storm_file = "file")
load("storm-v2@2x.png", storm_2x_file = "file")
load("sunny-v2.png", sunny_file = "file")
load("sunny-v2@2x.png", sunny_2x_file = "file")
load("thanksgiving-v2.png", thanksgiving_file = "file")
load("thanksgiving-v2@2x.png", thanksgiving_2x_file = "file")
load("time.star", "time")
load("valentines-day-v2.png", valentines_file = "file")
load("valentines-day-v2@2x.png", valentines_2x_file = "file")
load("windy-v2.png", windy_file = "file")
load("windy-v2@2x.png", windy_2x_file = "file")

DEFAULT_ZIP = "19125"
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_LATITUDE = 39.9526
DEFAULT_LONGITUDE = -75.1652

SCENES = {
    "christmas": christmas_file.readall("rb"),
    "cinco-de-mayo": cinco_file.readall("rb"),
    "clear-night": clear_night_file.readall("rb"),
    "cloudy": cloudy_file.readall("rb"),
    "cold": cold_file.readall("rb"),
    "halloween": halloween_file.readall("rb"),
    "hot": hot_file.readall("rb"),
    "july-4th": july_fourth_file.readall("rb"),
    "new-years": new_years_file.readall("rb"),
    "oedi-fall": oedi_fall_file.readall("rb"),
    "oedi-spring": oedi_spring_file.readall("rb"),
    "oedi-summer": oedi_summer_file.readall("rb"),
    "oedi-winter": oedi_winter_file.readall("rb"),
    "rain": rain_file.readall("rb"),
    "snow": snow_file.readall("rb"),
    "st-patricks-day": st_patricks_file.readall("rb"),
    "storm": storm_file.readall("rb"),
    "sunny": sunny_file.readall("rb"),
    "thanksgiving": thanksgiving_file.readall("rb"),
    "valentines-day": valentines_file.readall("rb"),
    "windy": windy_file.readall("rb"),
}

SCENES_2X = {
    "christmas": christmas_2x_file.readall("rb"),
    "cinco-de-mayo": cinco_2x_file.readall("rb"),
    "clear-night": clear_night_2x_file.readall("rb"),
    "cloudy": cloudy_2x_file.readall("rb"),
    "cold": cold_2x_file.readall("rb"),
    "halloween": halloween_2x_file.readall("rb"),
    "hot": hot_2x_file.readall("rb"),
    "july-4th": july_fourth_2x_file.readall("rb"),
    "new-years": new_years_2x_file.readall("rb"),
    "oedi-fall": oedi_fall_2x_file.readall("rb"),
    "oedi-spring": oedi_spring_2x_file.readall("rb"),
    "oedi-summer": oedi_summer_2x_file.readall("rb"),
    "oedi-winter": oedi_winter_2x_file.readall("rb"),
    "rain": rain_2x_file.readall("rb"),
    "snow": snow_2x_file.readall("rb"),
    "st-patricks-day": st_patricks_2x_file.readall("rb"),
    "storm": storm_2x_file.readall("rb"),
    "sunny": sunny_2x_file.readall("rb"),
    "thanksgiving": thanksgiving_2x_file.readall("rb"),
    "valentines-day": valentines_2x_file.readall("rb"),
    "windy": windy_2x_file.readall("rb"),
}

MONTHS = [
    "",
    "JANUARY",
    "FEBRUARY",
    "MARCH",
    "APRIL",
    "MAY",
    "JUNE",
    "JULY",
    "AUGUST",
    "SEPTEMBER",
    "OCTOBER",
    "NOVEMBER",
    "DECEMBER",
]

THUNDER_CODES = [95, 96, 99]
SNOW_CODES = [71, 73, 75, 77, 85, 86]
RAIN_CODES = [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]
CLOUD_CODES = [1, 2, 3, 45, 48]

def main(config):
    zip_code = config.str("zip_code", DEFAULT_ZIP)
    weather = get_weather(zip_code)
    timezone = weather.get("timezone") or DEFAULT_TIMEZONE
    now = time.now().in_location(timezone)

    kate_override = config.bool("kate_override", False)
    kate_season = config.str("kate_season", "automatic")

    if kate_override:
        scene_name = "oedi-" + get_kate_season(now, kate_season)
    else:
        holiday_scene = get_holiday_scene(now)
        scene_name = holiday_scene or weather.get("scene") or "cloudy"
    temperature = weather.get("temperature")

    width, height = canvas.size()
    scale = 2 if canvas.is2x() else 1
    scenes = SCENES_2X if canvas.is2x() else SCENES
    background = render.Image(
        src = scenes.get(scene_name, scenes["cloudy"]),
        width = width,
        height = height,
    )

    info_frame = render.Stack(
        children = [
            background,
            get_weather_panel(now, temperature, scale),
        ],
    )
    date_frame = render.Stack(
        children = [
            background,
            get_date_panel(now, scale),
        ],
    )

    return render.Root(
        delay = 4000,
        max_age = 180,
        show_full_animation = True,
        child = render.Animation(children = [info_frame, date_frame]),
    )

def get_weather(zip_code):
    cache_key = "weathercats:last:" + zip_code
    location = get_location(zip_code)
    params = {
        "latitude": str(location["latitude"]),
        "longitude": str(location["longitude"]),
        "current": "temperature_2m,weather_code,wind_speed_10m,is_day",
        "temperature_unit": "fahrenheit",
        "wind_speed_unit": "mph",
        "timezone": "auto",
        "forecast_days": "1",
    }
    response = http.get(
        "https://api.open-meteo.com/v1/forecast",
        params = params,
        ttl_seconds = 900,
    )

    if response.status_code == 200:
        payload = response.json()
        current = payload.get("current") or {}
        temperature = current.get("temperature_2m")
        weather_code = current.get("weather_code")
        wind_speed = current.get("wind_speed_10m") or 0
        is_day = current.get("is_day")

        if temperature != None and weather_code != None:
            result = {
                "scene": choose_weather_scene(
                    weather_code,
                    temperature,
                    wind_speed,
                    is_day,
                ),
                "temperature": temperature,
                "timezone": payload.get("timezone") or location["timezone"],
            }
            cache.set(cache_key, json.encode(result), ttl_seconds = 86400)
            return result

    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    return {
        "scene": "cloudy",
        "temperature": None,
        "timezone": location["timezone"],
    }

def get_location(zip_code):
    cache_key = "weathercats:location:" + zip_code
    cached = cache.get(cache_key)
    if cached != None:
        return json.decode(cached)

    response = http.get(
        "https://geocoding-api.open-meteo.com/v1/search",
        params = {
            "name": zip_code,
            "count": "1",
            "language": "en",
            "format": "json",
            "countryCode": "US",
        },
        ttl_seconds = 86400,
    )

    if response.status_code == 200:
        payload = response.json()
        results = payload.get("results") or []
        if len(results) > 0:
            first = results[0]
            location = {
                "latitude": first.get("latitude"),
                "longitude": first.get("longitude"),
                "timezone": first.get("timezone") or DEFAULT_TIMEZONE,
            }
            cache.set(cache_key, json.encode(location), ttl_seconds = 604800)
            return location

    return {
        "latitude": DEFAULT_LATITUDE,
        "longitude": DEFAULT_LONGITUDE,
        "timezone": DEFAULT_TIMEZONE,
    }

def choose_weather_scene(weather_code, temperature, wind_speed, is_day):
    if weather_code in THUNDER_CODES:
        return "storm"
    if weather_code in SNOW_CODES:
        return "snow"
    if weather_code in RAIN_CODES:
        return "rain"
    if wind_speed >= 20:
        return "windy"
    if temperature <= 32:
        return "cold"
    if temperature >= 85:
        return "hot"
    if weather_code in CLOUD_CODES:
        return "cloudy"
    if is_day == 0:
        return "clear-night"
    return "sunny"

def get_holiday_scene(now):
    month = now.month
    day = now.day

    if (month == 12 and day >= 29) or (month == 1 and day <= 4):
        return "new-years"
    if month == 2 and day >= 11 and day <= 17:
        return "valentines-day"
    if month == 3 and day >= 14 and day <= 20:
        return "st-patricks-day"
    if month == 5 and day >= 2 and day <= 8:
        return "cinco-de-mayo"
    if month == 7 and day >= 1 and day <= 7:
        return "july-4th"
    if (month == 10 and day >= 28) or (month == 11 and day <= 3):
        return "halloween"
    if is_thanksgiving_week(now):
        return "thanksgiving"
    if month == 12 and day >= 22 and day <= 28:
        return "christmas"
    return None

def is_thanksgiving_week(now):
    month = now.month
    day = now.day

    # Thanksgiving is the fourth Thursday in November. Its holiday week runs
    # Monday through Sunday, including December 1 when November 28 is Thursday.
    if month == 12 and day == 1:
        return humanize.day_of_week(now) == 0
    if month != 11:
        return False

    weekday = humanize.day_of_week(now)
    first_weekday = (weekday - ((day - 1) % 7)) % 7
    thanksgiving_day = 1 + ((4 - first_weekday) % 7) + 21
    return day >= thanksgiving_day - 3 and day <= thanksgiving_day + 3

def get_kate_season(now, configured_season):
    if configured_season != "automatic":
        return configured_season
    if now.month >= 3 and now.month <= 5:
        return "spring"
    if now.month >= 6 and now.month <= 8:
        return "summer"
    if now.month >= 9 and now.month <= 11:
        return "fall"
    return "winter"

def get_weather_panel(now, temperature, scale):
    panel_width = 34 if scale == 2 else 20
    panel_height = 11 * scale
    font = "6x10" if scale == 2 else "CG-pixel-3x5-mono"
    text_height = 10 if scale == 2 else 5
    temp_text = "--" if temperature == None else str(round_temperature(temperature)) + "°"
    time_text = now.format("3:04")

    return render.Box(
        width = panel_width,
        height = panel_height,
        color = "#000000",
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = temp_text,
                    color = temperature_color(temperature),
                    font = font,
                    height = text_height,
                ),
                render.Text(
                    content = time_text,
                    color = "#ffffff",
                    font = font,
                    height = text_height,
                ),
            ],
        ),
    )

def get_date_panel(now, scale):
    panel_width = 56 if scale == 2 else 38
    panel_height = 11 * scale
    font = "6x10" if scale == 2 else "CG-pixel-3x5-mono"
    text_height = 10 if scale == 2 else 5

    return render.Box(
        width = panel_width,
        height = panel_height,
        color = "#000000",
        child = render.Column(
            cross_align = "center",
            children = [
                render.Text(
                    content = MONTHS[now.month],
                    color = "#ffffff",
                    font = font,
                    height = text_height,
                ),
                render.Text(
                    content = str(now.day),
                    color = "#aaaaaa",
                    font = font,
                    height = text_height,
                ),
            ],
        ),
    )

def round_temperature(temperature):
    if temperature >= 0:
        return int(temperature + 0.5)
    return int(temperature - 0.5)

def temperature_color(temperature):
    if temperature == None:
        return "#aaaaaa"
    if temperature <= 32:
        return "#8dd8ff"
    if temperature <= 49:
        return "#4f8cff"
    if temperature <= 64:
        return "#a8d387"
    if temperature <= 74:
        return "#ffe066"
    if temperature <= 84:
        return "#ff9f43"
    return "#ff4d4d"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zip_code",
                name = "ZIP code",
                desc = "US ZIP code used for local weather and time.",
                icon = "locationDot",
                default = DEFAULT_ZIP,
            ),
            schema.Toggle(
                id = "kate_override",
                name = "Kate is visiting",
                desc = "Replace weather and holiday artwork with an Oedi seasonal scene.",
                icon = "cat",
                default = False,
            ),
            schema.Dropdown(
                id = "kate_season",
                name = "Oedi season",
                desc = "Automatically use the current season or choose one manually.",
                icon = "calendarDays",
                default = "automatic",
                options = [
                    schema.Option(display = "Automatic", value = "automatic"),
                    schema.Option(display = "Spring", value = "spring"),
                    schema.Option(display = "Summer", value = "summer"),
                    schema.Option(display = "Fall", value = "fall"),
                    schema.Option(display = "Winter", value = "winter"),
                ],
            ),
        ],
    )
