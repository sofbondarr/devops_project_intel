import os
import re
from datetime import datetime
from sqlalchemy import select
from app.models.log_model import LogEntry

# Абсолютный путь к папке logs
LOG_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "logs"))

# Регулярка: строгое соответствие формату "Created by ... from <ip>"
CREATED_PATTERN = re.compile(r"\[(.*?)\] Created by (\w+) from ([\d\.]+)")

async def load_logs(session):
    for fname in os.listdir(LOG_DIR):
        if not fname.endswith(".log"):
            continue

        with open(os.path.join(LOG_DIR, fname)) as f:
            for line in f:
                line = line.strip()
                match = CREATED_PATTERN.match(line)
                if not match:
                    continue  # пропускаем строки с неверным форматом

                ts_str, machine, ip = match.groups()
                ts = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")

                # Проверка на дубликаты
                exists = await session.execute(
                    select(LogEntry).where(
                        LogEntry.timestamp == ts,
                        LogEntry.machine == machine,
                        LogEntry.ip == ip
                    )
                )
                if not exists.scalars().first():
                    session.add(LogEntry(
                        timestamp=ts,
                        machine=machine,
                        ip=ip,
                    ))

    await session.commit()
