FROM elixir:otp-25-alpine
ENV PORT 4000
ENV NAME a@127.0.0.1

COPY . .

RUN mix setup

CMD elixir --name $NAME -S mix phx.server
