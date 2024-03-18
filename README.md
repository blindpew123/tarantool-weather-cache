Домашнее задание по Tarantool Cartridge:
Собрать приложение на Tarantool Cartridge, которые представляет throughput кэш для https://open-meteo.com/en

Приложение должно выставлять endpoint [http сервер](https://github.com/tarantool/http), которое проверяет кэш в собственном хранилище и отдает погоду по координатам.
Путь запроса такой:
1) Запрашиваем кэш
2) Если в кэше есть запись - отдаем её
3) Если нет - запрашивает по HTTP данные с open-meteo по координатам и кладет к себе в кэш
4) Отдаем из кэша данные

Приложение должно быть построено на Cartridge и состоять из 2 ролей:

1) router - эта роль [зависит](https://www.tarantool.io/en/doc/latest/book/cartridge/cartridge_dev/#defining-role-dependencies) от [vshard-router](https://www.tarantool.io/en/doc/latest/book/cartridge/cartridge_dev/#built-in-roles). Она выставляет наружу http handler, который через [vshard обращается к хранилищу](https://www.tarantool.io/en/doc/latest/reference/reference_rock/vshard/vshard_router/#router-api-call) (которое реализует роль `cache`) (проверяя наличие в кэше данных по координатам) или запрашивает open-meteo через встроенный [http клиент](https://www.tarantool.io/en/doc/latest/reference/reference_lua/http/#client-object-request). Также, если кэш пустой, то через вызов vshard, она кэш заполняет

2) cache - эта роль реализует хранение кэша и предоставляет API над кэшом (в виде `put` / `get`). Шардируется кэш (т.е. [вычисляет bucket_id](https://www.tarantool.io/en/doc/latest/reference/reference_rock/vshard/vshard_router/#lua-function.vshard.router.bucket_id_strcrc32)) по координатам (предлагаю просто конкатенировать долготу + широту в виде строк). Инвалидации кэша не требуется.

Для локальной разрбаботки и отладки - предлагаю использовать [Cartridge CLI](https://github.com/tarantool/cartridge-cli)

Полезные ссылки:
Cartridge - https://www.tarantool.io/en/doc/latest/book/cartridge/
Cartridge github - https://github.com/tarantool/cartridge
Пример кэша на Cartridge - https://github.com/tarantool/examples/blob/master/cache
Tarantool Cartridge на Хабре (1) - https://habr.com/ru/companies/vk/articles/465503/
Tarantool Cartridge на Хабре (2) - https://habr.com/ru/companies/vk/articles/588046/




# Simple Tarantool Cartridge-based application

This a simplest application based on Tarantool Cartridge.

## Quick start

To build application and setup topology:

```bash
cartridge build
cartridge start -d
cartridge replicasets setup --bootstrap-vshard
```

Now you can visit http://localhost:8081 and see your application's Admin Web UI.

**Note**, that application stateboard is always started by default.
See [`.cartridge.yml`](./.cartridge.yml) file to change this behavior.

## Application

Application entry point is [`init.lua`](./init.lua) file.
It configures Cartridge, initializes admin functions and exposes metrics endpoints.
Before requiring `cartridge` module `package_compat.cfg()` is called.
It configures package search path to correctly start application on production
(e.g. using `systemd`).

## Roles

Application has one simple role, [`app.roles.custom`](./app/roles/custom.lua).
It exposes `/hello` and `/metrics` endpoints:

```bash
curl localhost:8081/hello
curl localhost:8081/metrics
```

Also, Cartridge roles [are registered](./init.lua)
(`vshard-storage`, `vshard-router` and `metrics`).

You can add your own role, but don't forget to register in using
`cartridge.cfg` call.

## Instances configuration

Configuration of instances that can be used to start application
locally is places in [instances.yml](./instances.yml).
It is used by `cartridge start`.

## Topology configuration

Topology configuration is described in [`replicasets.yml`](./replicasets.yml).
It is used by `cartridge replicasets setup`.

## Tests

Simple unit and integration tests are placed in [`test`](./test) directory.

First, we need to install test dependencies:

```bash
./deps.sh
```

Then, run linter:

```bash
.rocks/bin/luacheck .
```

Now we can run tests:

```bash
cartridge stop  # to prevent "address already in use" error
.rocks/bin/luatest -v
```

## Admin

Application has admin function [`probe`](./app/admin.lua) configured.
You can use it to probe instances:

```bash
cartridge start -d  # if you've stopped instances
cartridge admin probe \
  --name tarantool-weather-cache \
  --run-dir ./tmp/run \
  --uri localhost:3302
```
