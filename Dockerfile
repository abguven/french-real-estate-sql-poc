FROM python:3.13-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl gnupg2 apt-transport-https \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/prod.list \
        > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8888

CMD ["python", "-m", "jupyterlab", "--ip=0.0.0.0", "--no-browser", "--allow-root", \
     "--ServerApp.token=''", "--ServerApp.root_dir=/app"]
