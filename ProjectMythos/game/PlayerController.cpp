#include "PlayerController.h"

void PlayerController::update(float deltaTime) {
    handleInput(deltaTime);
    combat.update(deltaTime);
}

void PlayerController::handleInput(float) {
    // TODO: Connect to RTDink/Proton input layer
}
