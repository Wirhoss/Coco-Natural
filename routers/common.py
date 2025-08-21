# routers/common.py
from fastapi import Depends, HTTPException
from db import get_db, rows_to_dicts
import oracledb

def call_proc(conn, full_name: str, args: list = None):
    try:
        cur = conn.cursor()
        cur.callproc(full_name, args or [])
        conn.commit()
        return {"ok": True}
    except oracledb.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"DB error in {full_name}: {e}")

def call_proc_out_cursor(conn, full_name: str, args: list = None):
    try:
        cur = conn.cursor()
        out_cur = cur.var(oracledb.CURSOR)
        # Inserta el var de OUT al final si no lo incluyeron
        params = (args or []) + [out_cur]
        cur.callproc(full_name, params)
        rc = out_cur.getvalue()
        rows = rows_to_dicts(rc)
        return rows
    except oracledb.Error as e:
        raise HTTPException(status_code=500, detail=f"DB error in {full_name}: {e}")

def call_func_cursor(conn, full_name: str, args: list = None):
    try:
        cur = conn.cursor()
        rc = cur.callfunc(full_name, oracledb.CURSOR, args or [])
        rows = rows_to_dicts(rc)
        return rows
    except oracledb.Error as e:
        raise HTTPException(status_code=500, detail=f"DB error in {full_name}: {e}")

def call_func_scalar(conn, full_name: str, return_type, args: list = None):
    try:
        cur = conn.cursor()
        val = cur.callfunc(full_name, return_type, args or [])
        return val
    except oracledb.Error as e:
        raise HTTPException(status_code=500, detail=f"DB error in {full_name}: {e}")

def exec_named_proc_omit_defaults(conn, pkg: str, proc: str, named_args: dict):
    try:
        cur = conn.cursor()
        # Construye "begin pkg.proc(p1=>:p1, p2=>:p2); end;"
        placeholders = ", ".join([f"{k}=>:{k}" for k in named_args.keys()])
        sql = f"begin {pkg}.{proc}({placeholders}); end;"
        cur.execute(sql, named_args)
        conn.commit()
        return {"ok": True}
    except oracledb.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500,
                            detail=f"DB error in {pkg}.{proc}: {e}")
