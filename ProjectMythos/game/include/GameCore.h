#pragma once
#include <functional>
#include <memory>
#include <optional>
#include <string>

class WorldGen;
class PlayerController;

class GameCore {
public:
    enum class State {
        Boot,
        MainMenu,
        InWorld,
        InBattle,
        Pause
    };

    struct RealmDescriptor {
        std::string realmId;
        int layerIndex{0};
    };

    using SaveCallback = std::function<bool(const std::string& slot, const RealmDescriptor& realm, State state)>;
    using LoadCallback = std::function<std::optional<RealmDescriptor>(const std::string& slot)>;
    using RealmSwitchCallback = std::function<bool(const RealmDescriptor& realm)>;

    GameCore();
    ~GameCore();

    void init();
    void update(float deltaTime);

    bool startNewGame(const RealmDescriptor& realm);
    bool requestLoad(const std::string& slot);
    bool requestSave(const std::string& slot);

    void enterBattle();
    void concludeBattle();
    void pause();
    void resume();
    void returnToMenu();
    bool requestRealmSwitch(const RealmDescriptor& realm);

    void setSaveCallback(SaveCallback cb) noexcept;
    void setLoadCallback(LoadCallback cb) noexcept;
    void setRealmSwitchCallback(RealmSwitchCallback cb) noexcept;

    State getState() const noexcept;
    const RealmDescriptor& getActiveRealm() const noexcept;
    bool isPauseActive() const noexcept;

private:
    void changeState(State newState);
    bool isTransitionAllowed(State from, State to) const noexcept;
    bool prepareRealm(const RealmDescriptor& realm);

    State state_;
    bool bootComplete_;
    std::optional<State> pausedFrom_;
    RealmDescriptor activeRealm_;
    SaveCallback saveCallback_;
    LoadCallback loadCallback_;
    RealmSwitchCallback realmSwitchCallback_;
    std::unique_ptr<WorldGen> world_;
    std::unique_ptr<PlayerController> player_;
};
