#include lethalbeats\ServerControl\groups;
#include lethalbeats\servercontrol\commands;

// groups
#define GUEST 0
#define DEVELOPER 1
#define OWNER 2
#define ADMIN 3
#define MODERATOR 4
#define VIP 5

init()
{
    lethalbeats\ServerControl\groups::init();
    lethalbeats\ServerControl\commands::init();

    // guid, group
    giveGroup("0100000000002414", DEVELOPER);
}
