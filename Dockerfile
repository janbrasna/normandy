FROM python:3.7-slim@sha256:225c394936740d17b1bd6aaa68731c53668947d2b38e44056b4b4a101c1ae6db
WORKDIR /app
RUN groupadd --gid 10001 app && useradd -g app --uid 10001 --shell /usr/sbin/nologin app
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    gcc libpq-dev curl apt-transport-https libffi-dev openssh-client gnupg python-dev libgmp3-dev

# Install node from NodeSource
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_8.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_8.x jessie main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install yarn

# Install Poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
ENV PATH "/root/.poetry/bin:${PATH}"

# Make and activate a Python virtualenv
RUN python -m venv /opt/venv
ENV PATH "/opt/venv/bin:${PATH}"
ENV VIRTUAL_ENV="/opt/venv"

# Install dependencies
COPY ./package.json /app/package.json
COPY ./yarn.lock /app/yarn.lock
RUN yarn install --frozen-lockfile
COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry install --no-dev --no-root --no-interaction --verbose

COPY . /app
RUN DJANGO_CONFIGURATION=Build python ./manage.py collectstatic --no-input && \
    mkdir -p media && chown app:app media

USER app
ENV DJANGO_SETTINGS_MODULE=normandy.settings \
    DJANGO_CONFIGURATION=Production \
    PORT=8000 \
    CMD_PREFIX="" \
    NEW_RELIC_CONFIG_FILE=newrelic.ini
EXPOSE $PORT

CMD $CMD_PREFIX gunicorn \
    --log-file - \
    --worker-class ${GUNICORN_WORKER_CLASS:-sync} \
    --max-requests ${GUNICORN_MAX_REQUESTS:-0} \
    normandy.wsgi:application
