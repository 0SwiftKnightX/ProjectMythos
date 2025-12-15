#ifndef PROJECTMYTHOS_HAS_ENGINE
#define PROJECTMYTHOS_HAS_ENGINE 0
#endif

#if PROJECTMYTHOS_HAS_ENGINE
#include "GameCore.h"
#else
#include <iostream>
#endif

int main() {
#if PROJECTMYTHOS_HAS_ENGINE
    GameCore game;
    game.init();
    game.update(0.016f);
#else
    std::cerr << "ProjectMythos built without RTDink/Proton integration; no engine runtime available." << std::endl;
#endif
    return 0;
}
