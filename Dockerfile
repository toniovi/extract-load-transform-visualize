# List of python devcontainer images here: https://github.com/devcontainers/images/tree/main/src/python
FROM ubuntu:22.04

ARG USERNAME=developer
ARG CONTAINER_TIMEZONE=Europe/Paris

# Install sudo and other minimal dependencies
RUN apt-get update && apt-get install -y sudo curl unzip git gcc

# Create a new user and add to sudoers
RUN useradd -m -s /bin/bash $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the new user
USER $USERNAME

# Set the same wd as in the devcontainer.json
WORKDIR /workspaces/extract-load-transform-visualize

# Copy files as the new user
COPY --chown=$USERNAME:$USERNAME . .

# Set timezone non-interactively
RUN sudo ln -fs /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata


# Install task for all users
RUN sudo sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

# Install project dependencies
RUN task install_project_dependencies_in_docker_container
