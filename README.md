# TakeOff

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server` or run the nodes startup script `./node_X.bash`

## With Docker

- Run `docker build . -t takeoff` to build the image
- Then run `docker run -e PORT={PORT} -e NAME={NAME} --network host -d takeoff` with any `PORT` and a `NAME`. For example: `docker run -e PORT=4000 -e NAME=a@127.0.0.1 --network host -d takeoff`

## Escenarios

### Escenario 1: se levanta un nodo nuevo A

1. El nodo A arranca en un estado `heating_engines`
2. Los procesos (flight, booking y alert) del nodo nuevo se comunican con su proceso equivalente en un nodo B del cluster para obtener el estado
3. Si el nodo B que recibe el pedido esta en `heating_engines` devuelve el error. El nodo A vuelve a intentarlo con otro nodo
4. Si ningun nodo responde con un estado, se asume que se esta comenzando de cero y se genera un estado inicial
5. El nodo A pasa a estado `ready`

### Escenario 2: se reinicia el coordinator

> Se esta levantando un coordinator para un vuelo que ya se habia empezado a vender

1. El coordinator se levanta en estado `heating_engines`
2. Conoce, a traves de su nombre, que vuelo esta coordinando
3. El coordinator se comunica con todos los procesos Flight consultando por el vuelo
4. El coordinator compara las respuestas y se queda con la que tenga el timestamp mayor
5. Pasa a estado `ready`

### Otros

#### Cuando el coordinator confirma un booking

- responde al que inicio el pedido con la confirmacion
- hace broadcast a todos los procesos Flight para que actualicen su estado
- chequea si el vuelo quedo completo y si es asi, se notifica al proceso Subscription del nodo propio del vuelo cerrado

#### Cuando el coordinator rechaza un booking

- responde al que inicio el pedido con el rechazo y le pasa el estado del vuelo para que lo corrija

#### Cuando el coordinator detecta que se acabo el tiempo de oferta

- se notifica al proceso Subscription del nodo propio del vuelo cerrado

#### Cuando el proceso Subscription recibe una notificación de un cierre de Flight

- busca los usuarios subscriptos y crea una task para el envio de esas notificaciones

#### Cuando se crea un nuevo Flight

- el proceso Flight crea un coordinator para ese flight
- el proceso Flight hace broadcast a todos los procesos Flight para que actualicen su estado
- se notifica el vuelo al proceso Alert del nodo propio

#### Cuando se crea una Alert

- el proceso Alert broadcastea a todos los procesos Alert para que actualicen su estado

#### Cuando el proceso alert recibe una notificación de un Flight

- busca las alerts que matcheen y crea una task para el envio de esas notificaciones

---

## Estado

### Flights

```json
{
  "1234": {
    "type": "Boeing 737",
    "seats": {
      "window": 25,
      "aisle": 25,
      "middle": 25
    },
    "datetime": "24-06-2025 00:00:00",
    "origin": "Buenos Aires",
    "destination": "Madrid",
    "created_at": "24-06-2023 00:00:00",
    "offer_duration": 10
  }
}
```

### Bookings

```json
[
  {
    "user_id": "111ABC",
    "user_name": "Manolo",
    "flight_id": "1234",
    "seats": {
      "window": 0,
      "aisle": 5,
      "middle": 0
    }
  }
]
```

### Alerts

```json
[
  {
    "user_id": "111ABC",
    "user_name": "Manolo",
    "date": "24-06-2025",
    "origin": "Buenos Aires",
    "destination": "Madrid",
    "webhook_url": "http://localhost:8080/alert/111ABC"
  }
]
```

### Flight Subscription

```json
{
  "1234": {
    "111ABC": {
      "user_name": "Manolo",
      "webhook_url": "http://localhost:8080/flight/1234"
    }
  }
}
```
