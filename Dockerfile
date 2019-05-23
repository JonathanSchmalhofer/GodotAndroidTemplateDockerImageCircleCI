# ====================================================================== #
# Godot Android Template Builder Docker Image
# ---------------------------------------------------------------------- #
#   based on AndroidSDK Docker Image from thyrlian
#   Source: https://github.com/thyrlian/AndroidSDK
# ====================================================================== #

# Base image
# ---------------------------------------------------------------------- #
FROM ubuntu:bionic

# Author
# ---------------------------------------------------------------------- #
LABEL maintainer "jonathan.schmalhofer@gmail.com"

# support multiarch: i386 architecture
# install Java
# install essential tools
# install Qt
RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses5 lib32z1 zlib1g:i386 && \
    apt-get install -y --no-install-recommends openjdk-8-jdk && \
    apt-get install -y --no-install-recommends git wget unzip apt-utils python3 scons

# download and install Gradle
# https://services.gradle.org/distributions/
ARG GRADLE_VERSION=5.2.1
RUN cd /opt && \
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip gradle*.zip && \
    ls -d */ | sed 's/\/*$//g' | xargs -I{} mv {} gradle && \
    rm gradle*.zip

# download and install Kotlin compiler
# https://github.com/JetBrains/kotlin/releases/latest
ARG KOTLIN_VERSION=1.3.21
RUN cd /opt && \
    wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip && \
    unzip *kotlin*.zip && \
    rm *kotlin*.zip

# download and install Android SDK
# https://developer.android.com/studio/#downloads
ARG ANDROID_SDK_VERSION=4333796
ENV ANDROID_HOME /opt/android-sdk
RUN mkdir -p ${ANDROID_HOME} && cd ${ANDROID_HOME} && \
    wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip && \
    unzip *tools*linux*.zip && \
    rm *tools*linux*.zip

# download and install Android NDK
# https://developer.android.com/ndk/downloads/
ARG ANDROID_NDK_VERSION=r19c
ENV ANDROID_NDK_HOME /opt/android-ndk
ENV ANDROID_NDK_ROOT ${ANDROID_NDK_HOME}
RUN mkdir -p ${ANDROID_NDK_HOME} && cd ${ANDROID_NDK_HOME} && \
    wget -q https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
    unzip *ndk*linux*.zip && \
    rm *ndk*linux*.zip

# set the environment variables
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV GRADLE_HOME /opt/gradle
ENV KOTLIN_HOME /opt/kotlinc
ENV PATH ${PATH}:${GRADLE_HOME}/bin:${KOTLIN_HOME}/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin
ENV _JAVA_OPTIONS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap
# WORKAROUND: for issue https://issuetracker.google.com/issues/37137213
ENV LD_LIBRARY_PATH ${ANDROID_HOME}/emulator/lib64:${ANDROID_HOME}/emulator/lib64/qt/lib

# accept the license agreements of the SDK components
ADD tools/license_accepter.sh /opt/
RUN chmod +x /opt/license_accepter.sh && /opt/license_accepter.sh $ANDROID_HOME

# Create debug key store
#    Source: http://docs.godotengine.org/en/latest/getting_started/workflow/export/exporting_for_android.html#doc-exporting-for-android
RUN keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999

ADD tools/supervisord.conf /etc/supervisor/conf.d/
CMD ["/usr/bin/supervisord"]
