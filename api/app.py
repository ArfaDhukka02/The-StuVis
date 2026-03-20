import time
import os
import mysql.connector
from mysql.connector import Error
from flask import Flask, jsonify, request

app = Flask(__name__)

def get_conn():
    """Retry connecting to MySQL up to 30 times with 2s delay."""
    for attempt in range(30):
        try:
            conn = mysql.connector.connect(
                host=os.environ["DB_HOST"],
                user=os.environ["DB_USER"],
                password=os.environ["DB_PASS"],
                database=os.environ["DB_NAME"],
                connection_timeout=5,
            )
            if conn.is_connected():
                return conn
        except Error as e:
            print(f"[DB] Attempt {attempt+1}/30 failed: {e} — retrying in 2s")
            time.sleep(2)
    raise RuntimeError("Could not connect to MySQL after 30 attempts")

# Warm up DB connection on startup
print("[startup] Waiting for MySQL to be ready...")
_warmup = get_conn()
_warmup.close()
print("[startup] MySQL is ready!")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/students")
def students():
    major = request.args.get("major")
    conn = get_conn()
    cur = conn.cursor()
    if major:
        cur.execute("SELECT id, name, major, gpa FROM students WHERE major = %s ORDER BY gpa DESC;", (major,))
    else:
        cur.execute("SELECT id, name, major, gpa FROM students ORDER BY name;")
    rows = [{"id": r[0], "name": r[1], "major": r[2], "gpa": float(r[3])} for r in cur.fetchall()]
    cur.close(); conn.close()
    return jsonify(rows)

@app.get("/students/top")
def top_students():
    limit = request.args.get("limit", 10, type=int)
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT id, name, major, gpa FROM students ORDER BY gpa DESC LIMIT %s;", (limit,))
    rows = [{"id": r[0], "name": r[1], "major": r[2], "gpa": float(r[3])} for r in cur.fetchall()]
    cur.close(); conn.close()
    return jsonify(rows)

@app.get("/analytics/gpa-by-major")
def gpa_by_major():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        SELECT major, ROUND(AVG(gpa), 3) as avg_gpa, COUNT(*) as student_count
        FROM students
        GROUP BY major
        ORDER BY avg_gpa DESC;
    """)
    rows = [{"major": r[0], "avg_gpa": float(r[1]), "student_count": r[2]} for r in cur.fetchall()]
    cur.close(); conn.close()
    return jsonify(rows)

@app.get("/analytics/gpa-distribution")
def gpa_distribution():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        SELECT
            CASE
                WHEN gpa < 2.5  THEN 'Below 2.5'
                WHEN gpa < 3.0  THEN '2.5 - 2.99'
                WHEN gpa < 3.25 THEN '3.0 - 3.24'
                WHEN gpa < 3.5  THEN '3.25 - 3.49'
                WHEN gpa < 3.75 THEN '3.5 - 3.74'
                ELSE '3.75 - 4.0'
            END AS bucket,
            COUNT(*) AS cnt
        FROM students
        GROUP BY bucket
        ORDER BY MIN(gpa);
    """)
    rows = [{"bucket": r[0], "count": r[1]} for r in cur.fetchall()]
    cur.close(); conn.close()
    return jsonify(rows)

@app.get("/analytics/summary")
def summary():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("""
        SELECT
            COUNT(*)              as total,
            ROUND(AVG(gpa), 3)   as avg_gpa,
            MAX(gpa)              as highest_gpa,
            MIN(gpa)              as lowest_gpa,
            COUNT(DISTINCT major) as major_count
        FROM students;
    """)
    r = cur.fetchone()
    cur.close(); conn.close()
    return jsonify({
        "total_students": r[0],
        "avg_gpa":        float(r[1]),
        "highest_gpa":    float(r[2]),
        "lowest_gpa":     float(r[3]),
        "major_count":    r[4]
    })

@app.get("/analytics/students-per-major")
def students_per_major():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("SELECT major, COUNT(*) as count FROM students GROUP BY major ORDER BY count DESC;")
    rows = [{"major": r[0], "count": r[1]} for r in cur.fetchall()]
    cur.close(); conn.close()
    return jsonify(rows)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)