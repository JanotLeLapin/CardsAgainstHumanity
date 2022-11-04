# Cards against humanity

Arguably the funniest game in the world. Requires friends.

## Building and running

Here's how you can run this on your machine. You'll need the following tools:

- [Elixir](https://elixir-lang.org)
- [NodeJS](https://nodejs.org)
- [PNPM](https://pnpm.io)

```sh
git clone https://github.com/JanotLeLapin/CardsAgainstHumanity
cd CardsAgainstHumanity
```

### GUI

Now let's build the graphical interface, made with SolidJS:

```sh
pnpm i # Download dependencies
pnpm build # Build
```

### Server

We can finally compile the WebSocket server, written in Elixir:

```sh
cd server
mix deps.get # Download dependencies
mix do compile # Build
```

You may now run the server with: `mix run --no-halt`. Go ahead and open `http://localhost:5000` in your favorite browser to see the results!

## Config file

This implementation doesn't come with cards out of the box (for legal reasons), so you'll need to come up with your own. Take a look at the [example config file](./config.example.toml) if you need inspiration, and store your actual config at the root in a `config.toml` file.
