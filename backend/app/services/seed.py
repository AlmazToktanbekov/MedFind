"""
Seed script — вставляет тестовые данные в базу данных.
Запуск: python -m app.services.seed
"""
import asyncio
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models import *  # noqa: F401,F403 — регистрируем все модели


async def seed():
    async with AsyncSessionLocal() as db:
        # Проверяем, есть ли уже данные
        result = await db.execute(select(Doctor))
        if result.scalars().first():
            print("Данные уже добавлены, пропускаем.")
            return

        # ─── Клиники (10 штук) ─────────────────────────────────────────
        clinics = [
            Clinic(
                name_ru="Клиника Авиценна", name_kg="Авиценна клиникасы", name_en="Avicenna Clinic",
                category_ru="Терапия",
                description_ru="Многопрофильная клиника с широким спектром медицинских услуг.",
                address_ru="г. Бишкек, ул. Киевская, 96",
                phone="+996 312 660 660", latitude=42.8746, longitude=74.5698,
                rating=4.8, reviews_count=124, status="active",
                working_hours_ru="Пн-Пт 08:00-20:00, Сб 09:00-16:00",
            ),
            Clinic(
                name_ru="МЦ Американ Хоспитал", name_kg="Американ Хоспитал МЦ", name_en="American Hospital",
                category_ru="Многопрофильная",
                description_ru="Международный медицинский центр с современным оборудованием.",
                address_ru="г. Бишкек, ул. Логвиненко, 38",
                phone="+996 312 511 511", latitude=42.8690, longitude=74.5892,
                rating=4.6, reviews_count=89, status="active",
                working_hours_ru="Ежедневно 08:00-22:00",
            ),
            Clinic(
                name_ru="Кардиоцентр Бишкек", name_kg="Бишкек Кардиоцентри", name_en="Bishkek Cardiac Center",
                category_ru="Кардиология",
                description_ru="Специализированный центр лечения сердечно-сосудистых заболеваний.",
                address_ru="г. Бишкек, пр. Манаса, 56",
                phone="+996 312 900 900", latitude=42.8800, longitude=74.5750,
                rating=4.9, reviews_count=201, status="active",
                working_hours_ru="Пн-Пт 09:00-18:00",
            ),
            Clinic(
                name_ru="ГорБольница №1", name_kg="Шаар ооруканасы №1", name_en="City Hospital #1",
                category_ru="Хирургия",
                description_ru="Городская хирургическая больница, экстренная помощь 24/7.",
                address_ru="г. Бишкек, ул. Тоголока Молдо, 1",
                phone="+996 312 665 665", latitude=42.8710, longitude=74.6012,
                rating=4.2, reviews_count=315, status="active",
                working_hours_ru="Круглосуточно",
            ),
            Clinic(
                name_ru="Стоматология Smile", name_kg="Smile тиш клиникасы", name_en="Smile Dental Clinic",
                category_ru="Стоматология",
                description_ru="Современная стоматология: лечение, протезирование, имплантация.",
                address_ru="г. Бишкек, ул. Чуй, 144",
                phone="+996 312 777 444", latitude=42.8730, longitude=74.5830,
                rating=4.7, reviews_count=78, status="active",
                working_hours_ru="Пн-Сб 09:00-20:00",
            ),
            Clinic(
                name_ru="Детская клиника Солнышко", name_kg="Күнчүгүш балдар клиникасы", name_en="Sunshine Kids Clinic",
                category_ru="Педиатрия",
                description_ru="Специализированная педиатрическая клиника для детей от 0 до 18 лет.",
                address_ru="г. Бишкек, ул. Ахунбаева, 92",
                phone="+996 312 550 550", latitude=42.8650, longitude=74.5720,
                rating=4.9, reviews_count=187, status="active",
                working_hours_ru="Пн-Пт 08:00-20:00, Сб 09:00-17:00",
            ),
            Clinic(
                name_ru="Офтальмологический центр Зрение", name_kg="Зрение офтальмология борбору", name_en="Vision Eye Center",
                category_ru="Офтальмология",
                description_ru="Лечение болезней глаз, лазерная коррекция зрения.",
                address_ru="г. Бишкек, ул. Московская, 177",
                phone="+996 312 610 610", latitude=42.8760, longitude=74.5860,
                rating=4.8, reviews_count=93, status="active",
                working_hours_ru="Пн-Пт 09:00-18:00, Сб 09:00-14:00",
            ),
            Clinic(
                name_ru="ЛОР-центр Слух и Речь", name_kg="ЛОР борбору", name_en="ENT Center",
                category_ru="Оториноларингология",
                description_ru="Диагностика и лечение заболеваний уха, горла и носа.",
                address_ru="г. Бишкек, пр. Жибек Жолу, 432",
                phone="+996 312 430 430", latitude=42.8680, longitude=74.5780,
                rating=4.5, reviews_count=56, status="active",
                working_hours_ru="Пн-Пт 08:30-17:30",
            ),
            Clinic(
                name_ru="МРТ и КТ центр Диагностика", name_kg="МРТ жана КТ диагностика борбору", name_en="MRI & CT Diagnostics",
                category_ru="Рентгенологические исследования",
                description_ru="МРТ, КТ, УЗИ — точная диагностика на современном оборудовании.",
                address_ru="г. Бишкек, ул. Байтик Баатыра, 28",
                phone="+996 312 840 840", latitude=42.8820, longitude=74.5900,
                rating=4.6, reviews_count=142, status="active",
                working_hours_ru="Пн-Вс 08:00-22:00",
            ),
            Clinic(
                name_ru="Центр Женского Здоровья Ана", name_kg="Ана аял ден соолук борбору", name_en="Ana Women's Health Center",
                category_ru="Акушерство и гинекология",
                description_ru="Ведение беременности, гинекология, репродуктология.",
                address_ru="г. Бишкек, ул. Ибраимова, 115",
                phone="+996 312 720 720", latitude=42.8705, longitude=74.5940,
                rating=4.9, reviews_count=234, status="active",
                working_hours_ru="Пн-Пт 08:00-19:00, Сб 09:00-15:00",
            ),
        ]
        for c in clinics:
            db.add(c)
        await db.flush()

        # ─── Врачи (10 штук) ───────────────────────────────────────────
        doctors = [
            Doctor(
                full_name_ru="Айгуль Мамытбекова",
                full_name_kg="Айгул Мамытбекова",
                full_name_en="Aigul Mamytbekova",
                specialization_ru="Кардиолог",
                specialization_en="Cardiologist",
                bio_ru="Врач-кардиолог высшей категории. Опыт 15 лет. Специализируется на лечении ИБС и сердечной недостаточности.",
                experience_years=15,
                clinic_id=clinics[2].id,
                address_ru="г. Бишкек, пр. Манаса, 56",
                has_online=True, has_offline=True,
                online_price=1500.0, offline_price=2500.0,
                online_duration_min=30, offline_duration_min=45,
                rating=4.9, reviews_count=87, status="active",
            ),
            Doctor(
                full_name_ru="Нурлан Токтосунов",
                full_name_kg="Нурлан Токтосунов",
                full_name_en="Nurlan Toktosunov",
                specialization_ru="Терапевт",
                specialization_en="General Practitioner",
                bio_ru="Терапевт первой категории. Лечение ОРВИ, гриппа, хронических заболеваний. Онлайн-консультации доступны.",
                experience_years=8,
                clinic_id=clinics[0].id,
                address_ru="г. Бишкек, ул. Киевская, 96",
                has_online=True, has_offline=True,
                online_price=800.0, offline_price=1500.0,
                online_duration_min=20, offline_duration_min=30,
                rating=4.6, reviews_count=42, status="active",
            ),
            Doctor(
                full_name_ru="Зульфия Кадырова",
                full_name_kg="Зульфия Кадырова",
                full_name_en="Zulfiya Kadyrova",
                specialization_ru="Акушер-гинеколог",
                specialization_en="Obstetrician-Gynecologist",
                bio_ru="Акушер-гинеколог высшей категории. Ведение беременности, УЗИ, лечение гинекологических заболеваний.",
                experience_years=12,
                clinic_id=clinics[9].id,
                address_ru="г. Бишкек, ул. Ибраимова, 115",
                has_online=False, has_offline=True,
                offline_price=2000.0, offline_duration_min=40,
                rating=4.8, reviews_count=156, status="active",
            ),
            Doctor(
                full_name_ru="Адилет Жакыпбеков",
                full_name_kg="Адилет Жакыпбеков",
                full_name_en="Adilet Zhakypbekov",
                specialization_ru="Невролог",
                specialization_en="Neurologist",
                bio_ru="Невролог. Лечение головных болей, мигрени, невритов, нарушений сна.",
                experience_years=6,
                address_ru="г. Бишкек, ул. Ахунбаева, 45",
                has_online=True, has_offline=True,
                online_price=1200.0, offline_price=2000.0,
                online_duration_min=30, offline_duration_min=40,
                rating=4.5, reviews_count=28, status="active",
            ),
            Doctor(
                full_name_ru="Гульнара Осмонова",
                full_name_kg="Гулнара Осмонова",
                full_name_en="Gulnara Osmonova",
                specialization_ru="Дерматолог",
                specialization_en="Dermatologist",
                bio_ru="Дерматолог-косметолог. Лечение акне, экземы, псориаза. Косметологические процедуры.",
                experience_years=10,
                address_ru="г. Бишкек, ул. Московская, 139",
                has_online=True, has_offline=True,
                online_price=1000.0, offline_price=1800.0,
                online_duration_min=25, offline_duration_min=35,
                rating=4.7, reviews_count=63, status="active",
            ),
            Doctor(
                full_name_ru="Бакыт Иманов",
                full_name_kg="Бакыт Иманов",
                full_name_en="Bakyt Imanov",
                specialization_ru="Педиатр",
                specialization_en="Pediatrician",
                bio_ru="Педиатр высшей категории. Ведение детей от 0 до 18 лет. Вакцинация, диагностика, лечение.",
                experience_years=14,
                clinic_id=clinics[5].id,
                address_ru="г. Бишкек, ул. Ахунбаева, 92",
                has_online=True, has_offline=True,
                online_price=700.0, offline_price=1300.0,
                online_duration_min=20, offline_duration_min=30,
                rating=4.9, reviews_count=201, status="active",
            ),
            Doctor(
                full_name_ru="Айнур Болотова",
                full_name_kg="Айнур Болотова",
                full_name_en="Ainur Bolotova",
                specialization_ru="Эндокринолог",
                specialization_en="Endocrinologist",
                bio_ru="Эндокринолог. Диагностика и лечение сахарного диабета, заболеваний щитовидной железы.",
                experience_years=9,
                address_ru="г. Бишкек, пр. Чуй, 200",
                has_online=True, has_offline=True,
                online_price=1100.0, offline_price=1900.0,
                online_duration_min=30, offline_duration_min=45,
                rating=4.7, reviews_count=74, status="active",
            ),
            Doctor(
                full_name_ru="Тимур Асанбеков",
                full_name_kg="Тимур Асанбеков",
                full_name_en="Timur Asanbekov",
                specialization_ru="Стоматолог",
                specialization_en="Dentist",
                bio_ru="Стоматолог-терапевт. Лечение кариеса, протезирование, профессиональная чистка зубов.",
                experience_years=7,
                clinic_id=clinics[4].id,
                address_ru="г. Бишкек, ул. Чуй, 144",
                has_online=False, has_offline=True,
                offline_price=2500.0, offline_duration_min=60,
                rating=4.6, reviews_count=45, status="active",
            ),
            Doctor(
                full_name_ru="Жылдыз Сейткалиева",
                full_name_kg="Жылдыз Сейткалиева",
                full_name_en="Zhyldyz Seitkaliyeva",
                specialization_ru="Офтальмолог",
                specialization_en="Ophthalmologist",
                bio_ru="Офтальмолог. Диагностика и лечение болезней глаз, подбор очков и линз.",
                experience_years=11,
                clinic_id=clinics[6].id,
                address_ru="г. Бишкек, ул. Московская, 177",
                has_online=True, has_offline=True,
                online_price=900.0, offline_price=1600.0,
                online_duration_min=20, offline_duration_min=35,
                rating=4.8, reviews_count=92, status="active",
            ),
            Doctor(
                full_name_ru="Канат Эргешов",
                full_name_kg="Канат Эргешов",
                full_name_en="Kanat Ergeshov",
                specialization_ru="Психотерапевт",
                specialization_en="Psychotherapist",
                bio_ru="Психотерапевт, КБТ-терапевт. Лечение тревожных расстройств, депрессии, фобий.",
                experience_years=5,
                address_ru="г. Бишкек, ул. Токтогула, 89",
                has_online=True, has_offline=True,
                online_price=1800.0, offline_price=2200.0,
                online_duration_min=50, offline_duration_min=60,
                rating=4.9, reviews_count=38, status="active",
            ),
        ]
        for d in doctors:
            db.add(d)
        await db.flush()

        # Контакты, услуги и расписание для первого врача
        from app.models.doctor import DoctorContact, DoctorService, DoctorSchedule

        contacts_data = [
            DoctorContact(doctor_id=doctors[0].id, type="phone", value="+996 700 123 456"),
            DoctorContact(doctor_id=doctors[0].id, type="whatsapp", value="+996700123456"),
            DoctorContact(doctor_id=doctors[0].id, type="telegram", value="aigul_doctor"),
            DoctorContact(doctor_id=doctors[1].id, type="phone", value="+996 550 234 567"),
            DoctorContact(doctor_id=doctors[1].id, type="whatsapp", value="+996550234567"),
            DoctorContact(doctor_id=doctors[2].id, type="phone", value="+996 700 345 678"),
            DoctorContact(doctor_id=doctors[2].id, type="telegram", value="zulfiya_gyn"),
            DoctorContact(doctor_id=doctors[3].id, type="phone", value="+996 551 456 789"),
            DoctorContact(doctor_id=doctors[3].id, type="whatsapp", value="+996551456789"),
            DoctorContact(doctor_id=doctors[4].id, type="phone", value="+996 700 567 890"),
            DoctorContact(doctor_id=doctors[4].id, type="instagram", value="gulnara_derm"),
            DoctorContact(doctor_id=doctors[5].id, type="phone", value="+996 552 678 901"),
            DoctorContact(doctor_id=doctors[6].id, type="phone", value="+996 700 789 012"),
            DoctorContact(doctor_id=doctors[7].id, type="phone", value="+996 553 890 123"),
            DoctorContact(doctor_id=doctors[8].id, type="phone", value="+996 700 901 234"),
            DoctorContact(doctor_id=doctors[9].id, type="phone", value="+996 554 012 345"),
            DoctorContact(doctor_id=doctors[9].id, type="whatsapp", value="+996554012345"),
        ]
        for c in contacts_data:
            db.add(c)

        services_data = [
            DoctorService(doctor_id=doctors[0].id, name_ru="Онлайн-консультация", price=1500.0),
            DoctorService(doctor_id=doctors[0].id, name_ru="Первичный приём", price=2500.0),
            DoctorService(doctor_id=doctors[0].id, name_ru="ЭКГ с расшифровкой", price=800.0),
            DoctorService(doctor_id=doctors[1].id, name_ru="Онлайн-консультация", price=800.0),
            DoctorService(doctor_id=doctors[1].id, name_ru="Первичный приём", price=1500.0),
            DoctorService(doctor_id=doctors[2].id, name_ru="Первичный приём", price=2000.0),
            DoctorService(doctor_id=doctors[2].id, name_ru="УЗИ при беременности", price=1200.0),
            DoctorService(doctor_id=doctors[3].id, name_ru="Онлайн-консультация", price=1200.0),
            DoctorService(doctor_id=doctors[3].id, name_ru="Первичный приём", price=2000.0),
            DoctorService(doctor_id=doctors[4].id, name_ru="Онлайн-консультация", price=1000.0),
            DoctorService(doctor_id=doctors[4].id, name_ru="Первичный приём", price=1800.0),
        ]
        for s in services_data:
            db.add(s)

        # Расписание для первых 3 врачей
        for doc_index in range(3):
            for day in range(5):  # Пн-Пт
                db.add(DoctorSchedule(
                    doctor_id=doctors[doc_index].id,
                    day_of_week=day,
                    start_time="09:00",
                    end_time="17:00",
                    is_available=True,
                ))

        # ─── Аптеки (10 компаний + филиалы) ───────────────────────────
        pharmacy_data = [
            ("Аптека Юг-Фарм",         "+996 312 880 880", "г. Бишкек, ул. Токтогула, 98",      42.8712, 74.5963, "Круглосуточно"),
            ("Аптека Ден-Сат",          "+996 312 445 445", "г. Бишкек, ул. Московская, 139",    42.8768, 74.5810, "Пн-Пт 08:00-22:00, Сб-Вс 09:00-21:00"),
            ("Аптека Неман",            "+996 312 660 770", "г. Бишкек, пр. Чуй, 150",           42.8734, 74.5880, "Круглосуточно"),
            ("Фарм-Сервис",             "+996 312 550 660", "г. Бишкек, ул. Ахунбаева, 132",     42.8645, 74.5740, "Ежедневно 08:00-22:00"),
            ("Аптека Гиппократ",        "+996 312 740 740", "г. Бишкек, ул. Байтик Баатыра, 45", 42.8822, 74.5915, "Пн-Пт 09:00-20:00, Сб 10:00-18:00"),
            ("Аптека 36.6",             "+996 312 380 380", "г. Бишкек, ул. Манаса, 42",          42.8798, 74.5762, "Круглосуточно"),
            ("Аптека Эко-Фарм",         "+996 312 490 490", "г. Бишкек, ул. Горького, 99",        42.8680, 74.6020, "Ежедневно 08:00-21:00"),
            ("Аптека Виталия",          "+996 312 660 990", "г. Бишкек, ул. Киевская, 55",        42.8750, 74.5680, "Пн-Вс 09:00-22:00"),
            ("Аптека при Кардиоцентре", "+996 312 900 901", "г. Бишкек, пр. Манаса, 56",          42.8802, 74.5755, "Пн-Пт 08:00-18:00"),
            ("Аптека Здоровье",         "+996 312 220 220", "г. Бишкек, пр. Жибек Жолу, 280",    42.8690, 74.5800, "Круглосуточно"),
        ]
        for name, phone, address, lat, lon, hours in pharmacy_data:
            company = PharmacyCompany(name=name, main_phone=phone)
            db.add(company)
            await db.flush()
            db.add(PharmacyBranch(
                company_id=company.id,
                address=address,
                latitude=lat,
                longitude=lon,
                phone=phone,
                working_hours=hours,
                is_active=True,
            ))

        # ─── Симптомы с маппингом специализаций ───────────────────────
        from app.models.symptom import Symptom, SymptomSpecialization

        symptom_data = [
            ("Боль в сердце", "heart",            ["Кардиолог"]),
            ("Головная боль", "head",              ["Невролог", "Терапевт"]),
            ("Кашель",        "lungs",             ["Терапевт", "Пульмонолог"]),
            ("Боль в животе", "stomach",           ["Гастроэнтеролог", "Хирург"]),
            ("Кожные проявления", "skin",          ["Дерматолог"]),
            ("Боль в суставах", "joints",          ["Ортопед", "Травматолог"]),
            ("Нарушение зрения", "eye",            ["Офтальмолог"]),
            ("Боль в горле",  "throat",            ["Оториноларинголог", "Терапевт"]),
            ("Сахарный диабет", "diabetes",        ["Эндокринолог"]),
            ("Стресс и тревога", "mental",         ["Психотерапевт"]),
            ("Беременность и роды", "pregnancy",   ["Акушер-гинеколог"]),
            ("Боль в ухе",    "ear",               ["Оториноларинголог"]),
            ("Проблемы с зубами", "teeth",         ["Стоматолог"]),
            ("Температура",   "temperature",       ["Терапевт", "Педиатр"]),
            ("Одышка",        "breath",            ["Пульмонолог", "Кардиолог"]),
        ]
        for name_ru, icon, specs in symptom_data:
            symptom = Symptom(name_ru=name_ru, icon=icon)
            db.add(symptom)
            await db.flush()
            for spec_ru in specs:
                db.add(SymptomSpecialization(symptom_id=symptom.id, specialization_ru=spec_ru))

        # ─── Статьи, первая помощь, советы ────────────────────────────
        from app.models.article import Article

        articles = [
            # Советы
            Article(
                title_ru="Как снизить артериальное давление без таблеток",
                category="health_tip",
                body_ru="Регулярные физические упражнения не менее 30 минут в день, снижение потребления соли до 5г в сутки, отказ от курения и алкоголя, управление стрессом — всё это помогает нормализовать давление без медикаментов.",
                is_published=True,
            ),
            Article(
                title_ru="5 продуктов для здорового сердца",
                category="health_tip",
                body_ru="Жирная рыба богата омега-3. Орехи снижают холестерин. Оливковое масло содержит полезные жиры. Авокадо укрепляет сосуды. Ягоды — антиоксиданты для сердца.",
                is_published=True,
            ),
            Article(
                title_ru="Как улучшить сон: 7 простых советов",
                category="health_tip",
                body_ru="Соблюдайте режим сна. Избегайте экранов за час до сна. Проветривайте комнату. Не ешьте тяжёлую пищу вечером. Занимайтесь спортом, но не поздно. Ограничьте кофеин после 14:00. Создайте комфортную обстановку.",
                is_published=True,
            ),
            # Первая помощь
            Article(
                title_ru="Первая помощь при обмороке",
                category="first_aid",
                body_ru="1. Уложите пострадавшего на спину.\n2. Приподнимите ноги на 30-40 см.\n3. Обеспечьте приток свежего воздуха.\n4. Расстегните одежду.\n5. Поднесите нашатырный спирт.\n6. При отсутствии сознания более 1 минуты — вызовите скорую.",
                is_published=True,
            ),
            Article(
                title_ru="Что делать при порезе",
                category="first_aid",
                body_ru="1. Промойте рану чистой проточной водой.\n2. Обработайте перекисью водорода или хлоргексидином.\n3. Наложите стерильную повязку.\n4. При глубоком порезе или сильном кровотечении — обратитесь в скорую.",
                is_published=True,
            ),
            Article(
                title_ru="Первая помощь при ожоге",
                category="first_aid",
                body_ru="1. Охладите место ожога под прохладной водой 15-20 минут.\n2. Не используйте лёд, масло или зубную пасту.\n3. Наложите стерильную повязку.\n4. При ожоге более 1% поверхности тела — вызовите скорую.",
                is_published=True,
            ),
            # Статьи
            Article(
                title_ru="Что нужно знать о вакцинации",
                category="article",
                body_ru="Вакцинация — самый эффективный способ профилактики инфекционных болезней. Современные вакцины проходят строгий контроль безопасности. Коллективный иммунитет защищает тех, кто не может быть вакцинирован по медицинским показаниям.",
                is_published=True,
            ),
            Article(
                title_ru="Правильное питание при диабете 2 типа",
                category="article",
                body_ru="Ограничьте простые углеводы и сладкое. Ешьте часто небольшими порциями. Отдавайте предпочтение продуктам с низким гликемическим индексом. Контролируйте размер порций. Пейте больше воды.",
                is_published=True,
            ),
            Article(
                title_ru="Как подготовиться к визиту врача",
                category="article",
                body_ru="Запишите все симптомы, включая когда они начались. Подготовьте список принимаемых лекарств. Возьмите результаты предыдущих анализов. Запишите вопросы, которые хотите задать. Не бойтесь переспрашивать, если что-то непонятно.",
                is_published=True,
            ),
            Article(
                title_ru="Признаки инсульта: не пропустите",
                category="article",
                body_ru="Используйте тест FAST:\n• Face (лицо) — попросите улыбнуться. Улыбка асимметрична?\n• Arms (руки) — поднять обе руки. Одна опускается?\n• Speech (речь) — попросите сказать фразу. Речь невнятна?\n• Time (время) — немедленно вызовите скорую!",
                is_published=True,
            ),
        ]
        for a in articles:
            db.add(a)

        # ─── Пользователи (admin + тестовые пациенты) ─────────────────
        from app.core.security import hash_password

        admin = User(
            phone="+996000000000",
            full_name="Администратор MedFind",
            role="admin",
            password_hash=hash_password("admin123"),
        )
        db.add(admin)

        test_patient = User(
            phone="+996700000001",
            full_name="Алмаз Тестов",
            role="patient",
            password_hash=hash_password("test123"),
        )
        db.add(test_patient)

        test_patient2 = User(
            phone="+996700000002",
            full_name="Айзат Пациентова",
            role="patient",
            password_hash=hash_password("test123"),
        )
        db.add(test_patient2)

        await db.commit()
        print("✅ Тестовые данные успешно добавлены!")
        print("   👨‍⚕️ Врачи: 10")
        print("   🏥 Клиники: 10")
        print("   💊 Аптеки: 10")
        print("   📰 Статьи: 10")
        print("   👤 Admin:    +996000000000 / admin123")
        print("   👤 Пациент1: +996700000001 / test123")
        print("   👤 Пациент2: +996700000002 / test123")


if __name__ == "__main__":
    asyncio.run(seed())
