#ifndef PROJECTMYTHOS_HAS_ENGINE
#define PROJECTMYTHOS_HAS_ENGINE 0
#endif

#if PROJECTMYTHOS_HAS_ENGINE
#include "GameCore.h"
#else
#include <iostream>
#endif

#include <iostream>

int main() {
#if PROJECTMYTHOS_HAS_ENGINE
    GameCore game;
    game.init();

    // Boot → MainMenu
    game.update(0.016f);

    // Start a new session inside the primary realm.
    if (!game.startNewGame({"Elderglade", 0})) {
        std::cerr << "Failed to initialise starting realm" << std::endl;
        return 1;
    }

    // Run a couple of frames of world simulation.
    game.update(0.016f);
    game.update(0.016f);

    // Demonstrate entering and exiting battle as part of the state machine.
    game.enterBattle();
    game.update(0.016f);
    game.concludeBattle();

    // Pause and resume flow.
    game.pause();
    game.resume();

    return 0;
}
