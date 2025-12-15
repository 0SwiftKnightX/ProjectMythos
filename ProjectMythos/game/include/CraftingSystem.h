#pragma once
#include <string>
#include <unordered_map>

class CraftingSystem {
public:
    bool craft(const std::string& recipeId);
private:
    std::unordered_map<std::string,int> inventory;
};
