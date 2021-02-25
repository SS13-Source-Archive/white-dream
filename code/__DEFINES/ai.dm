#define GET_AI_BEHAVIOR(behavior_type) SSai_controllers.ai_behaviors[behavior_type]
#define HAS_AI_CONTROLLER_TYPE(thing, type) istype(thing?.ai_controller, type)

#define AI_STATUS_ON		1
#define AI_STATUS_OFF		2


///Monkey checks
#define SHOULD_RESIST(source) (source.on_fire || source.buckled || HAS_TRAIT(source, TRAIT_RESTRAINED) || (source.pulledby && source.pulledby.grab_state > GRAB_PASSIVE))
#define IS_DEAD_OR_INCAP(source) (HAS_TRAIT(source, TRAIT_INCAPACITATED) || HAS_TRAIT(source, TRAIT_HANDS_BLOCKED) || IS_IN_STASIS(source) || source.stat)

///Max pathing attempts before auto-fail
#define MAX_PATHING_ATTEMPTS 30

///Flags for ai_behavior new()
#define AI_CONTROLLER_INCOMPATIBLE (1<<0)

///Does this task require movement from the AI before it can be performed?
#define AI_BEHAVIOR_REQUIRE_MOVEMENT (1<<0)
///Does this task let you perform the action while you move closer? (Things like moving and shooting)
#define AI_BEHAVIOR_MOVE_AND_PERFORM (1<<1)


///Monkey AI controller blackboard keys

#define BB_MONKEY_AGRESSIVE "BB_monkey_agressive"
#define BB_MONKEY_BEST_FORCE_FOUND "BB_monkey_bestforcefound"
#define BB_MONKEY_ENEMIES "BB_monkey_enemies"
#define BB_MONKEY_BLACKLISTITEMS "BB_monkey_blacklistitems"
#define BB_MONKEY_PICKUPTARGET "BB_monkey_pickuptarget"
#define BB_MONKEY_PICKPOCKETING "BB_monkey_pickpocketing"
#define BB_MONKEY_CURRENT_ATTACK_TARGET "BB_monkey_current_attack_target"
#define BB_MONKEY_TARGET_DISPOSAL "BB_monkey_target_disposal"
#define BB_MONKEY_DISPOSING "BB_monkey_disposing"
#define BB_MONKEY_RECRUIT_COOLDOWN "BB_monkey_recruit_cooldown"


/// Raper AI. Yes

#define BB_RAPER_AGRESSIVE 				"BB_raper_agressive"
#define BB_RAPER_ENEMIES 				"BB_raper_enemies"
#define BB_RAPER_CURRENT_ATTACK_TARGET 	"BB_raper_current_attack_target"
#define BB_RAPER_FUCKING 				"BB_raper_fucking"

///Vending machine AI controller blackboard keys

#define BB_VENDING_CURRENT_TARGET 		"BB_vending_current_target"
#define BB_VENDING_TILT_COOLDOWN 		"BB_vending_tilt_cooldown"
#define BB_VENDING_UNTILT_COOLDOWN 		"BB_vending_untilt_cooldown"
#define BB_VENDING_BUSY_TILTING 		"BB_vending_busy_tilting"
#define BB_VENDING_LAST_HIT_SUCCESFUL 	"BB_vending_last_hit_succesful"

/// Combat AI

#define BB_COMBAT_AI_ANGRY_GAY 		"BB_combat_ai_angry_gay"
#define BB_COMBAT_AI_ENEMIES 		"BB_combat_ai_enemies"
#define BB_COMBAT_AI_CURRENT_TARGET "BB_combat_ai_current_target"
#define BB_COMBAT_AI_WEAPON_TARGET  "BB_combat_ai_weapon_target"
#define BB_COMBAT_AI_WEAPON_BL	  	"BB_combat_ai_weapon_bl"
#define BB_COMBAT_AI_WOUNDED 		"BB_combat_ai_wounded"
#define BB_COMBAT_AI_STUPIDITY		"BB_combat_ai_stupidity"
#define BB_COMBAT_AI_SUICIDE_BOMBER "BB_combat_ai_suicide_bomber"

///Robot customer AI controller blackboard keys
#define BB_CUSTOMER_CURRENT_ORDER "BB_customer_current_order"
#define BB_CUSTOMER_MY_SEAT "BB_customer_my_seat"
#define BB_CUSTOMER_PATIENCE "BB_customer_patience"
#define BB_CUSTOMER_CUSTOMERINFO "BB_customer_customerinfo"
#define BB_CUSTOMER_EATING "BB_customer_eating"
#define BB_CUSTOMER_ATTENDING_VENUE "BB_customer_attending_avenue"
#define BB_CUSTOMER_LEAVING "BB_customer_leaving"
