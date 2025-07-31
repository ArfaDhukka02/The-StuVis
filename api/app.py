#importing flask to create web server from flask library
import time
import os
import mysql.connector
from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/students")
def students():
    conn = mysql.connector.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        database=os.environ["DB_NAME"],
    )
    cur = conn.cursor()
    cur.execute("SELECT id, name, major, gpa FROM students;")
    rows = [
        {"id": r[0], "name": r[1], "major": r[2], "gpa": float(r[3])}
        for r in cur.fetchall()
    ]
    cur.close()
    conn.close()
    return jsonify(rows)

if __name__ == "__main__":
    time.sleep(1)
    app.run(host="0.0.0.0", port=5000)

