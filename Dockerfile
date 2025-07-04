# Stage 1: Build environment
FROM python:3.11-slim-bookworm AS builder

RUN addgroup --system app && adduser --system --ingroup app app
WORKDIR /home/app

# Copy only requirements to cache them in docker layer
COPY --chown=app:app pyproject.toml poetry.lock* ./

# Add pipx binaries to PATH
ENV PATH="/root/.local/bin:/home/app/.local/bin:${PATH}"

# Install pipx
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev libffi-dev curl && \
    python -m pip install --upgrade pip && \
    python -m pip install pipx && \
    pipx ensurepath

# Install Poetry
RUN pipx install poetry && \
    poetry config virtualenvs.create true && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-interaction --no-ansi --no-root

# Copying the rest of the project
COPY app .

# Stage 2: Runtime environment
FROM python:3.11-slim-bookworm

RUN addgroup --system app && adduser --system --ingroup app app

# Set PATH for Poetry's virtual environment
ENV PATH="/home/app/.venv/bin:${PATH}"
ENV PYTHONPATH="/home/app/.venv/lib/python3.11/site-packages/"


# Update packages
RUN apt-get update && apt-get install -y --no-install-recommends

# Copy installed dependencies from builder stage
COPY --from=builder /home/app /home/app

WORKDIR /home/app

ENTRYPOINT ["untestables"]
CMD ["--help"]

