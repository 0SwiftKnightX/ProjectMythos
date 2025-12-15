#include "GameCore.h"

#include "PlayerController.h"
#include "WorldGen.h"

#include <stdexcept>
#include <utility>

namespace {
const char* toString(GameCore::State state) noexcept {
    switch (state) {
    case GameCore::State::Boot:
        return "Boot";
    case GameCore::State::MainMenu:
        return "MainMenu";
    case GameCore::State::InWorld:
        return "InWorld";
    case GameCore::State::InBattle:
        return "InBattle";
    case GameCore::State::Pause:
        return "Pause";
    }
    return "Unknown";
}
} // namespace

GameCore::GameCore()
    : state_(State::Boot),
      bootComplete_(false),
      activeRealm_({"", 0}) {}

GameCore::~GameCore() = default;

void GameCore::init() {
    world_ = std::make_unique<WorldGen>();
    player_ = std::make_unique<PlayerController>();
    state_ = State::Boot;
    bootComplete_ = false;
    pausedFrom_.reset();
    activeRealm_ = {"", 0};
}

void GameCore::update(float deltaTime) {
    if (!world_ || !player_) {
        throw std::logic_error("GameCore::init must be called before update");
    }

    switch (state_) {
    case State::Boot:
        if (!bootComplete_) {
            bootComplete_ = true;
        }
        changeState(State::MainMenu);
        break;
    case State::InWorld:
        player_->update(deltaTime);
        world_->update(deltaTime);
        break;
    case State::InBattle:
        player_->update(deltaTime);
        break;
    case State::MainMenu:
    case State::Pause:
        // Idle states: no per-frame simulation required here yet.
        break;
    }
}

bool GameCore::startNewGame(const RealmDescriptor& realm) {
    if (state_ != State::MainMenu) {
        throw std::logic_error("startNewGame is only valid from MainMenu");
    }
    if (!prepareRealm(realm)) {
        return false;
    }
    changeState(State::InWorld);
    return true;
}

bool GameCore::requestLoad(const std::string& slot) {
    if (state_ != State::MainMenu) {
        throw std::logic_error("requestLoad is only valid from MainMenu");
    }
    if (!loadCallback_) {
        return false;
    }
    const auto realm = loadCallback_(slot);
    if (!realm) {
        return false;
    }
    if (!prepareRealm(*realm)) {
        return false;
    }
    changeState(State::InWorld);
    return true;
}

bool GameCore::requestSave(const std::string& slot) {
    if (state_ == State::Boot || state_ == State::InBattle) {
        throw std::logic_error("Cannot save in the current state");
    }
    if (!saveCallback_) {
        return false;
    }
    return saveCallback_(slot, activeRealm_, state_);
}

void GameCore::enterBattle() {
    if (state_ != State::InWorld) {
        throw std::logic_error("enterBattle requires InWorld state");
    }
    changeState(State::InBattle);
}

void GameCore::concludeBattle() {
    if (state_ != State::InBattle) {
        throw std::logic_error("concludeBattle requires InBattle state");
    }
    changeState(State::InWorld);
}

void GameCore::pause() {
    if (state_ == State::Pause) {
        return;
    }
    if (state_ != State::InWorld && state_ != State::InBattle) {
        throw std::logic_error("pause is only valid from InWorld or InBattle");
    }
    pausedFrom_ = state_;
    changeState(State::Pause);
}

void GameCore::resume() {
    if (state_ != State::Pause || !pausedFrom_) {
        throw std::logic_error("resume requires an active pause state");
    }
    const auto returnState = *pausedFrom_;
    pausedFrom_.reset();
    changeState(returnState);
}

void GameCore::returnToMenu() {
    switch (state_) {
    case State::InWorld:
        changeState(State::MainMenu);
        break;
    case State::Pause:
        pausedFrom_.reset();
        changeState(State::MainMenu);
        break;
    case State::MainMenu:
        break;
    default:
        throw std::logic_error("returnToMenu not permitted from current state");
    }
}

bool GameCore::requestRealmSwitch(const RealmDescriptor& realm) {
    if (state_ != State::InWorld && state_ != State::Pause) {
        throw std::logic_error("Realm switching requires world or pause state");
    }
    return prepareRealm(realm);
}

void GameCore::setSaveCallback(SaveCallback cb) noexcept {
    saveCallback_ = std::move(cb);
}

void GameCore::setLoadCallback(LoadCallback cb) noexcept {
    loadCallback_ = std::move(cb);
}

void GameCore::setRealmSwitchCallback(RealmSwitchCallback cb) noexcept {
    realmSwitchCallback_ = std::move(cb);
}

GameCore::State GameCore::getState() const noexcept {
    return state_;
}

const GameCore::RealmDescriptor& GameCore::getActiveRealm() const noexcept {
    return activeRealm_;
}

bool GameCore::isPauseActive() const noexcept {
    return state_ == State::Pause;
}

void GameCore::changeState(State newState) {
    if (state_ == newState) {
        return;
    }
    if (!isTransitionAllowed(state_, newState)) {
        throw std::logic_error(std::string("Illegal transition from ") + toString(state_) + " to " + toString(newState));
    }
    state_ = newState;
    if (newState != State::Pause) {
        pausedFrom_.reset();
    }
}

bool GameCore::isTransitionAllowed(State from, State to) const noexcept {
    switch (from) {
    case State::Boot:
        return to == State::MainMenu;
    case State::MainMenu:
        return to == State::InWorld;
    case State::InWorld:
        return to == State::InBattle || to == State::Pause || to == State::MainMenu;
    case State::InBattle:
        return to == State::InWorld || to == State::Pause;
    case State::Pause:
        return to == State::InWorld || to == State::InBattle || to == State::MainMenu;
    }
    return false;
}

bool GameCore::prepareRealm(const RealmDescriptor& realm) {
    if (!world_) {
        throw std::logic_error("World generator not initialised");
    }
    bool ready = true;
    if (realmSwitchCallback_) {
        ready = realmSwitchCallback_(realm);
    }
    if (!ready) {
        return false;
    }
    activeRealm_ = realm;
    world_->generate();
    return true;
}
