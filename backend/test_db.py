from sqlalchemy import create_engine
import os

url = os.getenv(
    "DATABASE_URL", 
    "postgresql+psycopg2://humsukhan:humsukhan_pass@localhost/humsukhan_db"
)
print(f"Testing URL: {url}")
try:
    engine = create_engine(url)
    print(f"Dialect: {engine.dialect.name}")
    print(f"Driver: {engine.driver}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
