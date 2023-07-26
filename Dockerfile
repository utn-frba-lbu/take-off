FROM elixir:otp-25-alpine
ENV PORT 4000
ENV NAME a@127.0.0.1
ENV COOKIE blue_label

COPY . .

RUN mix setup
RUN mix compile

CMD elixir --name $NAME --cookie $COOKIE -S mix phx.server
