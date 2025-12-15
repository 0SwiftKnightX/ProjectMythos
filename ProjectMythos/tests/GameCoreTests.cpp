#include "GameCore.h"

#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>

class TestRunner {
public:
    void expect(bool condition, const std::string& message) {
        ++total_;
        if (!condition) {
            ++failed_;
            std::cerr << "[FAIL] " << message << '\n';
        }
    }

    template <typename Func>
    void expectThrows(Func&& fn, const std::string& message) {
        ++total_;
        try {
            fn();
            ++failed_;
            std::cerr << "[FAIL] " << message << " (no exception)" << '\n';
        } catch (const std::logic_error&) {
            // Expected path
        } catch (...) {
            ++failed_;
            std::cerr << "[FAIL] " << message << " (unexpected exception type)" << '\n';
        }
    }

    int report() const {
        if (failed_ == 0) {
            std::cout << "All tests passed (" << total_ << ")" << std::endl;
        } else {
            std::cerr << failed_ << " of " << total_ << " tests failed" << std::endl;
        }
        return failed_;
    }

private:
    int total_{0};
    int failed_{0};
};

int main() {
    TestRunner runner;

    GameCore game;
    game.init();

    runner.expect(game.getState() == GameCore::State::Boot, "Initial state should be Boot");

    int switchCount = 0;
    game.setRealmSwitchCallback([&](const GameCore::RealmDescriptor& realm) {
        ++switchCount;
        return realm.layerIndex >= 0;
    });

    runner.expectThrows([&]() { game.enterBattle(); }, "Cannot enter battle before menu");

    game.update(0.0f);
    runner.expect(game.getState() == GameCore::State::MainMenu, "Boot update should lead to MainMenu");

    runner.expect(game.startNewGame({"Elderglade", 0}), "Starting a new game should succeed");
    runner.expect(switchCount == 1, "Realm switch callback should trigger for new game");
    runner.expect(game.getState() == GameCore::State::InWorld, "New game should enter InWorld");
    runner.expect(game.getActiveRealm().realmId == "Elderglade", "Active realm should match new game");

    game.pause();
    runner.expect(game.isPauseActive(), "Pause should activate from InWorld");
    game.resume();
    runner.expect(game.getState() == GameCore::State::InWorld, "Resume should return to InWorld");

    game.enterBattle();
    runner.expect(game.getState() == GameCore::State::InBattle, "Battle entry should switch state");

    game.pause();
    runner.expect(game.isPauseActive(), "Pause should activate from InBattle");
    game.resume();
    runner.expect(game.getState() == GameCore::State::InBattle, "Resume from pause should restore InBattle");

    runner.expectThrows([&]() { game.resume(); }, "Cannot resume when not paused");

    runner.expectThrows([&]() { game.returnToMenu(); }, "Cannot return to menu mid-battle");
    game.concludeBattle();
    runner.expect(game.getState() == GameCore::State::InWorld, "Concluding battle returns to world");

    bool saveTriggered = false;
    game.setSaveCallback([&](const std::string& slot, const GameCore::RealmDescriptor& realm, GameCore::State state) {
        saveTriggered = (slot == "slotA" && realm.realmId == game.getActiveRealm().realmId && state == GameCore::State::InWorld);
        return saveTriggered;
    });

    runner.expect(game.requestSave("slotA"), "Saving should succeed with callback");
    runner.expect(saveTriggered, "Save callback should flag execution");

    game.returnToMenu();
    runner.expect(game.getState() == GameCore::State::MainMenu, "Return to menu should succeed from InWorld");

    runner.expectThrows([&]() { game.requestRealmSwitch({"Forbidden", 1}); }, "Realm switch unavailable from MainMenu");

    bool loadTriggered = false;
    game.setLoadCallback([&](const std::string& slot) -> std::optional<GameCore::RealmDescriptor> {
        loadTriggered = (slot == "slotA");
        if (!loadTriggered) {
            return std::nullopt;
        }
        return GameCore::RealmDescriptor{"LoadedRealm", 2};
    });

    runner.expect(game.requestLoad("slotA"), "Loading should succeed from MainMenu");
    runner.expect(loadTriggered, "Load callback should run");
    runner.expect(game.getState() == GameCore::State::InWorld, "Successful load returns to InWorld");
    runner.expect(game.getActiveRealm().realmId == "LoadedRealm", "Loaded realm should be active");
    runner.expect(switchCount == 2, "Realm callback should run on load");

    runner.expect(game.requestRealmSwitch({"DeepHollow", 1}), "Realm switch should work in-world");
    runner.expect(game.getActiveRealm().realmId == "DeepHollow", "Realm should update after switch");
    runner.expect(switchCount == 3, "Realm callback should count switch");

    runner.expect(!game.requestRealmSwitch({"Invalid", -1}), "Realm switch should fail when callback rejects");
    runner.expect(game.getActiveRealm().realmId == "DeepHollow", "Failed realm switch keeps previous realm");
    runner.expect(switchCount == 4, "Realm callback runs even on failure");

    game.enterBattle();
    runner.expectThrows([&]() { game.requestSave("slotB"); }, "Saving in battle should throw");
    game.concludeBattle();

    return runner.report();
}
