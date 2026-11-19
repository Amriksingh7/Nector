import sqlite3, sys
db = sqlite3.connect(":memory:")
for f in ["01_schema.sql", "02_sample_data.sql"]:
    db.executescript(open(f).read())
print("tables:", [r[0] for r in db.execute("select name from sqlite_master where type='table'")])
for q in open("03_queries.sql").read().split(";"):
    q = q.strip()
    if not q: continue
    print("\n>>", q.splitlines()[0])
    try:
        for r in db.execute(q): print("  ", r)
    except Exception as e: print("  ERROR", e)
