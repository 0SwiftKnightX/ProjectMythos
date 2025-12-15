#pragma once
#include <string>
#include <vector>

struct Quest {
    std::string id;
    std::string title;
    std::string state;
};

class QuestManager {
public:
    void add(const Quest& q);
    void update(float dt);
private:
    std::vector<Quest> quests;
};
