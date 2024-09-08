#include lethalbeats\survival\armories\_armories;

init()
{
    level.onOpenPage = ::onOpenPage;
    level.onSelectOption = ::onSelectOption;
    level.onUpdateOption = ::onUpdateOption;
    level.isUpgradeOption = ::isUpgradeOption;
    level.isOwnedOption = ::isOwnedOption;
    level.isDisabledOption = ::isDisabledOption;

    lethalbeats\weapons::init();
    lethalbeats\survival\armories\_spawn::init();
}
