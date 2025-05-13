from fastapi import FastAPI, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.config import get_session, engine
from app.models.log_model import Base, LogEntry
from app.parser.log_parser import load_logs
from sqlalchemy import select
from datetime import datetime

from typing import Optional
from fastapi.middleware.cors import CORSMiddleware
import asyncio

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def parse_datetime(value: str) -> datetime:
    formats = [
        "%Y-%m-%d/%H:%M:%S",
        "%Y/%m/%d/%H:%M:%S"
    ]
    for fmt in formats:
        try:
            return datetime.strptime(value, fmt)
        except ValueError:
            continue
    raise HTTPException(status_code=400, detail=f"Invalid datetime format: {value}")

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    asyncio.create_task(log_updater())

@app.get("/logs")
async def get_logs(
    start: Optional[str] = Query(None),
    end: Optional[str] = Query(None),
    session: AsyncSession = Depends(get_session)
):
    query = select(LogEntry)
    if start:
        start_dt = parse_datetime(start)
        query = query.where(LogEntry.timestamp >= start_dt)
    if end:
        end_dt = parse_datetime(end)
        query = query.where(LogEntry.timestamp <= end_dt)

    result = await session.execute(query)
    logs = result.scalars().all()

    return [{
        "machine": log.machine,
        "ip": log.ip,
        "time": log.timestamp.strftime("%H:%M:%S"),
        "date": log.timestamp.strftime("%Y-%m-%d"),
    } for log in logs]

async def log_updater():
    while True:
        async for session in get_session():
            await load_logs(session)
        await asyncio.sleep(1800)  # 30 минут
