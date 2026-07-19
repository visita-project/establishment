//go:build wireinject

package main

import "github.com/goforj/wire"

type App struct{}

func NewApp() *App { return &App{} }

func Initialize() *App {
	panic(wire.Build(NewApp))
}
