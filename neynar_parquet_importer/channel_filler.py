import os
import json
from dotenv import load_dotenv
from sqlalchemy import Column, VARCHAR
from sqlalchemy.orm import declarative_base
from rich.logging import RichHandler
import logging
import urllib3
from sqlalchemy.dialects.postgresql import insert as pg_insert  # Import the correct insert function

from neynar_parquet_importer.db import init_db  # Use absolute import

# Load environment variables
load_dotenv()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(name)s - %(message)s",
    datefmt="%X",
    handlers=[RichHandler()],
)
LOGGER = logging.getLogger("channel_filler")

# API configuration
API_KEY = os.getenv('NEYNAR_API_KEY')
API_URL = 'https://api.neynar.com/v2/farcaster/channel/list'
LIMIT = 200

Base = declarative_base()

class Channel(Base):
    __tablename__ = 'channels'
    id = Column(VARCHAR, primary_key=True)
    name = Column(VARCHAR)
    description = Column(VARCHAR)
    image_url = Column(VARCHAR)
    url = Column(VARCHAR)
    follower_count = Column(VARCHAR)  # Add this line

http = urllib3.PoolManager()

def fetch_channels(cursor=None):
    headers = {
        'accept': 'application/json',
        'api_key': API_KEY
    }
    params = {
        'limit': LIMIT
    }
    if cursor:
        params['cursor'] = cursor

    url = f"{API_URL}?{'&'.join([f'{k}={v}' for k, v in params.items()])}"
    response = http.request('GET', url, headers=headers)
    
    if response.status != 200:
        raise Exception(f"API request failed with status {response.status}")
    
    return json.loads(response.data.decode('utf-8'))

def upsert_channels(engine, channels):
    with engine.connect() as conn:
        for channel_data in channels:
            # Filter out unexpected fields
            valid_keys = {column.name for column in Channel.__table__.columns}
            filtered_data = {k: v for k, v in channel_data.items() if k in valid_keys}
            
            stmt = pg_insert(Channel).values(filtered_data)
            stmt = stmt.on_conflict_do_update(
                index_elements=['id'],
                set_={
                    'name': stmt.excluded.name,
                    'description': stmt.excluded.description,
                    'image_url': stmt.excluded.image_url,
                    'url': stmt.excluded.url,
                    'follower_count': stmt.excluded.follower_count  # Add this line if follower_count is relevant
                }
            )
            conn.execute(stmt)
        conn.commit()

def main():
    # Initialize database connection
    database_uri = os.getenv('LOCAL_DATABASE_URI')
    if not database_uri:
        raise ValueError("LOCAL_DATABASE_URI environment variable is not set")
    
    engine = init_db(database_uri, pool_size=5)

    # Create the channels table if it doesn't exist
    Base.metadata.create_all(engine)

    cursor = None
    total_channels = 0
    while True:
        data = fetch_channels(cursor)
        channels = data.get('channels', [])
        if not channels:
            break
        upsert_channels(engine, channels)
        total_channels += len(channels)
        LOGGER.info(f"Processed {len(channels)} channels. Total: {total_channels}")
        cursor = data.get('next', {}).get('cursor')
        if not cursor:
            break
    LOGGER.info(f"Finished processing. Total channels: {total_channels}")

if __name__ == "__main__":
    main()