#pragma once
#include <string>
#include "CombatSystem.h"

class PlayerController {
public:
    void update(float deltaTime);
private:
    void handleInput(float deltaTime);
    CombatSystem combat;
};
