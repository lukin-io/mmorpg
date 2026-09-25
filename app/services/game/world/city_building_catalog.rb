# frozen_string_literal: true

module Game
  module World
    # Source-backed city service labels and read-only catalog content. Airship
    # booking, the general Shop and Arena retain their dedicated workflows.
    class CityBuildingCatalog
      BUILDINGS = {
        "market" => {
          "title" => "Соляной Базар",
          "kind" => "market",
          "summary" => "Игровые лоты и аренда прилавков.",
          "stall_tiers" => [
            ["Витрина угля", 0, 100, 400, "15%"],
            ["Малый", 200, 250, 500, "5%"],
            ["Средний", 400, 450, 750, "4%"],
            ["Просторный", 600, 700, 1000, "3%"],
            ["Большой", 800, 1000, 1250, "2%"],
            ["Огромный", 1000, 2000, 1500, "1%"]
          ]
        },
        "junk_dealer" => {
          "title" => "Скупщик Пепла",
          "kind" => "junk_buyback",
          "summary" => "Скупает щепу, хвосты, приманки и бинты за NV без лицензии."
        },
        "numismatics" => {
          "title" => "Нумизматика Завесы",
          "kind" => "numismatics",
          "summary" => "Книга лотов одной валюты.",
          "commodity" => "Древняя монета Альвии"
        },
        "airship_station" => {
          "title" => "Станция Разломов",
          "kind" => "airship",
          "summary" => "Маршруты дирижаблей по разломам."
        },
        "hospital" => {
          "title" => "Лазарет Угля",
          "kind" => "hospital",
          "summary" => "Лечение, покой и аптека.",
          "tabs" => ["Лавка", "Комната отдыха", "Койка", "Аптека"],
          "goods" => [
            ["Сумка новичка-лекаря", "10 лёгких травм", 300, 33],
            ["Сумка опытного лекаря", "10 средних травм", 750, 28],
            ["Сумка мастера-лекаря", "10 тяжёлых травм", 1500, 143],
            ["Боевая аптечка", "1 боевая травма", 7000, 1]
          ]
        },
        "tavern" => {
          "title" => "Таверна Угольного Прилива",
          "kind" => "tavern",
          "summary" => "Еда, слухи и отдых угля: HP/MP сразу. Травмы — в Лазарете."
        },
        "workshop" => {
          "title" => "Смоляная Кузница",
          "kind" => "workshop",
          "summary" => "Крафт Смолокура: бинты, наборы, приманки."
        },
        "guard_tower" => {
          "title" => "Башня Дозора",
          "kind" => "guard",
          "summary" => "Живые переходы в соседние кварталы с текущей площади."
        },
        "city_hall" => {
          "title" => "Ратуша Угля",
          "kind" => "landmark",
          "summary" => "Указы города и доска стартовых договоров Пепельной Завесы."
        },
        "clan_hall" => {
          "title" => "Зал Клана Пепла",
          "kind" => "landmark",
          "summary" => "Клановый хаб. Войны секторов — отдельной системой."
        },
        "post" => {
          "title" => "Пепельная Почта",
          "kind" => "post",
          "summary" => "Личная записка персонажа. Межгородская почта — позже."
        },
        "magic_school" => {
          "title" => "Школа Завесы",
          "kind" => "landmark",
          "summary" => "Обучение магии и знаниям."
        },
        "library" => {
          "title" => "Архив Колоколов",
          "kind" => "landmark",
          "summary" => "Справочник механик Пепельной Завесы — как библиотека Mist War, но наш лор."
        },
        "general_school" => {
          "title" => "Общая Школа",
          "kind" => "landmark",
          "summary" => "Базовые умения и профессии."
        },
        "military_school" => {
          "title" => "Школа Клинка",
          "kind" => "landmark",
          "summary" => "Оружейные школы и строевая подготовка."
        },
        "dealer_house" => {
          "title" => "Дом Скупщика",
          "kind" => "landmark",
          "summary" => "Скупка трофеев. Рабочий прилавок — Скупщик Пепла на Рынке."
        },
        "souvenir_shop" => {
          "title" => "Лавка Реликвий",
          "kind" => "souvenir",
          "summary" => "Приманка, щепа и трава за NV без лицензии."
        },
        "auction" => {
          "title" => "Аукцион Соли",
          "kind" => "landmark",
          "summary" => "Игровой аукцион. Лоты подключим после экономики."
        },
        "obelisk" => {
          "title" => "Обелиск Завесы",
          "kind" => "obelisk",
          "summary" => "Привязка координат и возврат за NV."
        },
        "bank" => {
          "title" => "Банк Смолы",
          "kind" => "bank",
          "summary" => "Сейф NV и одна ячейка предмета вне кармана."
        },
        "temple" => {
          "title" => "Храм Чёрного Колокола",
          "kind" => "temple",
          "summary" => "Лёгкий обряд за NV снимает лёгкие травмы. Тяжёлые и боевые — в Лазарете."
        },
        "law_abode" => {
          "title" => "Обитель Закона",
          "kind" => "law",
          "summary" => "Объявление и смена склонности персонажа."
        },
        "prison" => {
          "title" => "Тюрьма Цистерны",
          "kind" => "landmark",
          "summary" => "Камеры для нарушителей порядка."
        },
        "gallows" => {
          "title" => "Виселица Пепла",
          "kind" => "landmark",
          "summary" => "Показательные казни — визуальный лор района."
        }
      }.freeze

      class << self
        def fetch(building_key, zone: nil)
          building = BUILDINGS[building_key.to_s]
          return building unless building_key.to_s == "airship_station" && zone&.city?

          title = zone.airship_station_title ||
            (zone.metadata.to_h["city_key"] == "forpost" ? "Станция Разломов" : "Станция Разломов")
          building.merge("title" => title)
        end

        def key?(building_key)
          BUILDINGS.key?(building_key.to_s)
        end

        def path_for(building_key)
          "/city/buildings/#{building_key}" if key?(building_key)
        end

        def accessible?(character:, building_key:)
          return false unless key?(building_key)

          position = CharacterPosition.includes(:zone).find_by(character_id: character&.id)
          return false unless position&.zone&.city?

          CityHotspot.for_zone(position.zone).any? do |hotspot|
            hotspot.action_params.to_h["feature"] == building_key.to_s &&
              hotspot.can_interact?(character)
          end
        end
      end
    end
  end
end
