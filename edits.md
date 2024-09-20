docker run -d --name neynar-postgres \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD=postgres \
    -e POSTGRES_DB=neynar_parquet_importer \
    -p 15432:5432 \
    -v neynar_postgres_data:/var/lib/postgresql/data \
    --network neynar-network \
    postgres:16
    
docker run --name neynar-importer \
    --env-file .env \
    -v $(pwd)/data/parquet:/usr/src/app/data/parquet \
    -v neynar_postgres_data:/var/lib/postgresql/data:ro \
    --network neynar-network \
    neynar-parquet-importer


# this one runs the fancy loading screen
docker run -it --name neynar-importer \
    --env-file .env \
    -e PYTHONUNBUFFERED=1 \
    -v $(pwd)/data/parquet:/usr/src/app/data/parquet \
    -v neynar_postgres_data:/var/lib/postgresql/data:ro \
    --network neynar-network \
    neynar-parquet-importer
