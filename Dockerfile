FROM php:7.3.28-cli-alpine3.13

MAINTAINER Nixus <nixus@nixus.cn>

LABEL description=" 补推tags "
LABEL exts=" 添加xlswriter扩展 "

ENV XLSWRITER_VERSION 1.3.7

RUN apk update --no-cache \
	&& apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS \
    && apk add --no-cache libzip-dev libpng-dev libmcrypt-dev libjpeg-turbo-dev libstdc++ freetype-dev git \
	## 编译必备
    && apk add --no-cache autoconf build-base pcre make \
	## 安装swoole依赖
	&& apk add --no-cache openssl-dev \
	## 安装php的redis依赖
    && pecl install -o -f redis \
	## 安装PHP的swoole扩展
	&& git clone https://gitee.com/swoole/swoole.git \
	&& ( \
		cd swoole && phpize \
		&& ./configure --enable-openssl --with-openssl-dir=/usr/include/openssl --enable-http2 --enable-mysqlnd --enable-debug-log \
		&& make && make install \
		&& cd .. && rm -rf swoole \
	) \
	## 安装PHP扩展：xlswriter 
	&& ( \
		curl -fsSL "https://pecl.php.net/get/xlswriter-${XLSWRITER_VERSION}.tgz" -o xlswriter.tgz \
		&& mkdir -p /tmp/xlswriter \
		&& tar -xf xlswriter.tgz -C /tmp/xlswriter --strip-components=1 \
		&& rm xlswriter.tgz \
		&& cd /tmp/xlswriter \
		&& phpize && ./configure --enable-reader && make && make install \
    ) \
	&& docker-php-ext-enable redis swoole xlswriter \
	&& docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo pdo_mysql bcmath gd zip pcntl \
    && apk del autoconf build-base pcre make gcc g++ musl-dev git pcre2 expat .phpize-deps \
	&& rm -rf /usr/src/* \
	&& rm -rf /tmp/*
