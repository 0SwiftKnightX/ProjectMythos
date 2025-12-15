#pragma once
#include <vector>
#include <string>

class MonsterTamer {
public:
    void captureCreature(const std::string& species);
    void summon(int index);
private:
    std::vector<std::string> tamedCreatures;
};
