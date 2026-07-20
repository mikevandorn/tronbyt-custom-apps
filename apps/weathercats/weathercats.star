load("cache.star", "cache")
load("christmas.png", christmas_file = "file")
load("christmas@2x.png", christmas_2x_file = "file")
load("cinco-de-mayo.png", cinco_file = "file")
load("cinco-de-mayo@2x.png", cinco_2x_file = "file")
load("clear-night.png", clear_night_file = "file")
load("clear-night@2x.png", clear_night_2x_file = "file")
load("cloudy.png", cloudy_file = "file")
load("cloudy@2x.png", cloudy_2x_file = "file")
load("encoding/json.star", "json")
load("halloween.png", halloween_file = "file")
load("halloween@2x.png", halloween_2x_file = "file")
load("hot.png", hot_file = "file")
load("hot@2x.png", hot_2x_file = "file")
load("http.star", "http")
load("humanize.star", "humanize")
load("july-4th.png", july_fourth_file = "file")
load("july-4th@2x.png", july_fourth_2x_file = "file")
load("new-years.png", new_years_file = "file")
load("new-years@2x.png", new_years_2x_file = "file")
load("rain.png", rain_file = "file")
load("rain@2x.png", rain_2x_file = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("snow-cold.png", snow_cold_file = "file")
load("snow-cold@2x.png", snow_cold_2x_file = "file")
load("st-patricks-day.png", st_patricks_file = "file")
load("st-patricks-day@2x.png", st_patricks_2x_file = "file")
load("storm.png", storm_file = "file")
load("storm@2x.png", storm_2x_file = "file")
load("sunny.png", sunny_file = "file")
load("sunny@2x.png", sunny_2x_file = "file")
load("thanksgiving.png", thanksgiving_file = "file")
load("thanksgiving@2x.png", thanksgiving_2x_file = "file")
load("time.star", "time")
load("valentines-day.png", valentines_file = "file")
load("valentines-day@2x.png", valentines_2x_file = "file")
load("windy.png", windy_file = "file")
load("windy@2x.png", windy_2x_file = "file")

DEFAULT_ZIP = "19125"
DEFAULT_TIMEZONE = "America/New_York"
DEFAULT_LATITUDE = 39.9526
DEFAULT_LONGITUDE = -75.1652

SCENES = {
    "christmas": christmas_file.readall("rb"),
    "cinco-de-mayo": cinco_file.readall("rb"),
    "clear-night": clear_night_file.readall("rb"),
    "cloudy": cloudy_file.readall("rb"),
    "halloween": halloween_file.readall("rb"),
    "hot": hot_file.readall("rb"),
    "july-4th": july_fourth_file.readall("rb"),
    "new-years": new_years_file.readall("rb"),
    "rain": rain_file.readall("rb"),
    "snow-cold": snow_cold_file.readall("rb"),
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
    "halloween": halloween_2x_file.readall("rb"),
    "hot": hot_2x_file.readall("rb"),
    "july-4th": july_fourth_2x_file.readall("rb"),
    "new-years": new_years_2x_file.readall("rb"),
    "rain": rain_2x_file.readall("rb"),
    "snow-cold": snow_cold_2x_file.readall("rb"),
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
        return "snow-cold"
    if weather_code in RAIN_CODES:
        return "rain"
    if wind_speed >= 20:
        return "windy"
    if temperature <= 32:
        return "snow-cold"
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

    if (month == 12 and day == 31) or (month == 1 and day == 1):
        return "new-years"
    if month == 2 and day == 14:
        return "valentines-day"
    if month == 3 and day == 17:
        return "st-patricks-day"
    if month == 5 and day == 5:
        return "cinco-de-mayo"
    if month == 7 and day == 4:
        return "july-4th"
    if month == 10 and day == 31:
        return "halloween"
    if month == 11 and day >= 22 and day <= 28 and humanize.day_of_week(now) == 4:
        return "thanksgiving"
    if month == 12 and day == 25:
        return "christmas"
    return None

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
        ],
    )
