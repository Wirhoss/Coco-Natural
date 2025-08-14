import os
from typing import Generator
import oracledb
from fastapi import HTTPException

ORACLE_USER = "coco_natural"
ORACLE_PASSWORD = "7zMFrmrX$cy5s7%8"
ORACLE_DSN = "localhost:1521/XEPDB1"

def get_conn():
    try:
        # Use thin mode - no Oracle client required
        conn = oracledb.connect(
            user=ORACLE_USER, 
            password=ORACLE_PASSWORD, 
            dsn=ORACLE_DSN
        )
        return conn
    except oracledb.Error as e:
        raise HTTPException(status_code=500, detail=f"DB connection error: {e}")

def get_db() -> Generator:
    conn = get_conn()
    try:
        yield conn
    finally:
        try:
            conn.close()
        except Exception:
            pass

def rows_to_dicts(cursor):
    cols = [col[0].lower() for col in cursor.description]
    return [dict(zip(cols, row)) for row in cursor.fetchall()]