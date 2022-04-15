FROM python:3.9 as base

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools poetry
RUN poetry config virtualenvs.create false
RUN poetry config virtualenvs.create false
RUN poetry export --dev --without-hashes --no-interaction --no-ansi -f requirements.txt -o requirements.txt
RUN pip install --no-cache-dir -r requirements.txt


FROM python:3.9-slim

RUN apt-get -y update && apt-get install -y --no-install-recommends libpq-dev && rm -rf /var/lib/apt/lists/*

ENV PYTHONUNBUFFERED=1

COPY --from=base /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /your_app
COPY your_app .

ENV WORKERS=2
ENV THREADS=2
ENV PORT=8000

RUN python manage.py collectstatic --ignore rest_framework --link

# Disable debug after statics are collected
ENV DEBUG=0

# Written in a shell format to let variables be evaluated,
# thus container can be stopped only with "docker stop <container-name>" command
ENTRYPOINT gunicorn core.wsgi -w ${WORKERS} --threads ${THREADS} -b 0.0.0.0:${PORT}
