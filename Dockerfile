FROM ruby:3.4-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    tzdata

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development

# Copy application code
COPY . .

# Enable YJIT for production performance boost
ENV RUBY_YJIT_ENABLE=1

# Expose port
EXPOSE 4567

# Run the application with YJIT enabled
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
