FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Install Flutter SDK pinned to stable 3.41.7
ENV FLUTTER_HOME=/opt/flutter
RUN git clone https://github.com/flutter/flutter.git \
    --branch 3.41.7 \
    --depth 1 \
    $FLUTTER_HOME

ENV PATH="$FLUTTER_HOME/bin:$PATH"
RUN flutter --version

# Install Android command-line tools
ENV ANDROID_HOME=/opt/android-sdk
ARG CMDLINE_TOOLS_VERSION=11076708
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
    curl -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp && \
    mv /tmp/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

# Accept licenses and install required SDK components
RUN yes | sdkmanager --licenses && \
    sdkmanager \
      "platform-tools" \
      "platforms;android-35" \
      "build-tools;35.0.0"

# Tell Flutter where the Android SDK lives
RUN flutter config --android-sdk $ANDROID_HOME && \
    yes | flutter doctor --android-licenses || true

WORKDIR /workspace
