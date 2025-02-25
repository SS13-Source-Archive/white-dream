//////////////////////////////////////////////
//                                          //
//            MIDROUND RULESETS             //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround // Can be drafted once in a while during a round
	ruletype = "Midround"
	/// If the ruleset should be restricted from ghost roles.
	var/restrict_ghost_roles = TRUE
	/// What mob type the ruleset is restricted to.
	var/required_type = /mob/living/carbon/human
	var/list/living_players = list()
	var/list/living_antags = list()
	var/list/dead_players = list()
	var/list/list_observers = list()

/datum/dynamic_ruleset/midround/from_ghosts
	weight = 0
	required_type = /mob/dead/observer
	/// Whether the ruleset should call generate_ruleset_body or not.
	var/makeBody = TRUE

/datum/dynamic_ruleset/midround/trim_candidates()
	living_players = trim_list(mode.current_players[CURRENT_LIVING_PLAYERS])
	living_antags = trim_list(mode.current_players[CURRENT_LIVING_ANTAGS])
	dead_players = trim_list(mode.current_players[CURRENT_DEAD_PLAYERS])
	list_observers = trim_list(mode.current_players[CURRENT_OBSERVERS])

/datum/dynamic_ruleset/midround/proc/trim_list(list/L = list())
	var/list/trimmed_list = L.Copy()
	for(var/mob/M in trimmed_list)
		if (!istype(M, required_type))
			trimmed_list.Remove(M)
			continue
		if (!M.client) // Are they connected?
			trimmed_list.Remove(M)
			continue
		if(!mode.check_age(M.client, minimum_required_age))
			trimmed_list.Remove(M)
			continue
		if(antag_flag_override)
			if(!(antag_flag_override in M.client.prefs.be_special) || is_banned_from(M.ckey, list(antag_flag_override, ROLE_SYNDICATE)))
				trimmed_list.Remove(M)
				continue
		else
			if(!(antag_flag in M.client.prefs.be_special) || is_banned_from(M.ckey, list(antag_flag, ROLE_SYNDICATE)))
				trimmed_list.Remove(M)
				continue
		if (M.mind)
			if (restrict_ghost_roles && (M.mind.assigned_role in GLOB.exp_specialmap[EXP_TYPE_SPECIAL])) // Are they playing a ghost role?
				trimmed_list.Remove(M)
				continue
			if (M.mind.assigned_role in restricted_roles) // Does their job allow it?
				trimmed_list.Remove(M)
				continue
			if ((exclusive_roles.len > 0) && !(M.mind.assigned_role in exclusive_roles)) // Is the rule exclusive to their job?
				trimmed_list.Remove(M)
				continue
	return trimmed_list

// You can then for example prompt dead players in execute() to join as strike teams or whatever
// Or autotator someone

// IMPORTANT, since /datum/dynamic_ruleset/midround may accept candidates from both living, dead, and even antag players, you need to manually check whether there are enough candidates
// (see /datum/dynamic_ruleset/midround/autotraitor/ready(forced = FALSE) for example)
/datum/dynamic_ruleset/midround/ready(forced = FALSE)
	if (!forced)
		var/job_check = 0
		if (enemy_roles.len > 0)
			for (var/mob/M in mode.current_players[CURRENT_LIVING_PLAYERS])
				if (M.stat == DEAD || !M.client)
					continue // Dead/disconnected players cannot count as opponents
				if (M.mind && M.mind.assigned_role && (M.mind.assigned_role in enemy_roles) && (!(M in candidates) || (M.mind.assigned_role in restricted_roles)))
					job_check++ // Checking for "enemies" (such as sec officers). To be counters, they must either not be candidates to that rule, or have a job that restricts them from it

		var/threat = round(mode.threat_level/10)
		if (job_check < required_enemies[threat])
			return FALSE
	return TRUE

/datum/dynamic_ruleset/midround/from_ghosts/execute()
	var/list/possible_candidates = list()
	possible_candidates.Add(dead_players)
	possible_candidates.Add(list_observers)
	send_applications(possible_candidates)
	if(assigned.len > 0)
		return TRUE
	else
		return FALSE

/// This sends a poll to ghosts if they want to be a ghost spawn from a ruleset.
/datum/dynamic_ruleset/midround/from_ghosts/proc/send_applications(list/possible_volunteers = list())
	if (possible_volunteers.len <= 0) // This shouldn't happen, as ready() should return FALSE if there is not a single valid candidate
		message_admins("Possible volunteers was 0. This shouldn't appear, because of ready(), unless you forced it!")
		return
	message_admins("Polling [possible_volunteers.len] players to apply for the [name] ruleset.")
	log_game("DYNAMIC: Polling [possible_volunteers.len] players to apply for the [name] ruleset.")

	candidates = poll_ghost_candidates("The mode is looking for volunteers to become [antag_flag] for [name]", antag_flag, SSticker.mode, antag_flag_override ? antag_flag_override : antag_flag, poll_time = 300)

	if(!candidates || candidates.len <= 0)
		message_admins("The ruleset [name] received no applications.")
		log_game("DYNAMIC: The ruleset [name] received no applications.")
		mode.executed_rules -= src
		return

	message_admins("[candidates.len] players volunteered for the ruleset [name].")
	log_game("DYNAMIC: [candidates.len] players volunteered for [name].")
	review_applications()

/// Here is where you can check if your ghost applicants are valid for the ruleset.
/// Called by send_applications().
/datum/dynamic_ruleset/midround/from_ghosts/proc/review_applications()
	for (var/i = 1, i <= required_candidates, i++)
		if(candidates.len <= 0)
			if(i == 1)
				// We have found no candidates so far and we are out of applicants.
				mode.executed_rules -= src
			break
		var/mob/applicant = pick(candidates)
		candidates -= applicant
		if(!isobserver(applicant))
			if(applicant.stat == DEAD) // Not an observer? If they're dead, make them one.
				applicant = applicant.ghostize(FALSE)
			else // Not dead? Disregard them, pick a new applicant
				i--
				continue

		if(!applicant)
			i--
			continue

		var/mob/new_character = applicant

		if (makeBody)
			new_character = generate_ruleset_body(applicant)

		finish_setup(new_character, i)
		assigned += applicant
		notify_ghosts("[new_character] has been picked for the ruleset [name]!", source = new_character, action = NOTIFY_ORBIT, header="Something Interesting!")

/datum/dynamic_ruleset/midround/from_ghosts/proc/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/new_character = makeBody(applicant)
	new_character.dna.remove_all_mutations()
	return new_character

/datum/dynamic_ruleset/midround/from_ghosts/proc/finish_setup(mob/new_character, index)
	var/datum/antagonist/new_role = new antag_datum()
	setup_role(new_role)
	new_character.mind.add_antag_datum(new_role)
	new_character.mind.special_role = antag_flag

/datum/dynamic_ruleset/midround/from_ghosts/proc/setup_role(datum/antagonist/new_role)
	return

//////////////////////////////////////////////
//                                          //
//           SYNDICATE TRAITORS             //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/autotraitor
	name = "Syndicate Sleeper Agent"
	antag_datum = /datum/antagonist/traitor
	antag_flag = ROLE_TRAITOR
	protected_roles = list("Prisoner", "Russian Officer", "Trader", "Hacker", "Veteran", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Field Medic", "Exploration Crew")
	restricted_roles = list("Cyborg", "AI", "Позитронный мозг")
	required_candidates = 1
	weight = 7
	cost = 10
	requirements = list(50,40,30,20,10,10,10,10,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/autotraitor/acceptable(population = 0, threat = 0)
	var/player_count = mode.current_players[CURRENT_LIVING_PLAYERS].len
	var/antag_count = mode.current_players[CURRENT_LIVING_ANTAGS].len
	var/max_traitors = round(player_count / 10) + 1

	// adding traitors if the antag population is getting low
	var/too_little_antags = antag_count < max_traitors
	if (!too_little_antags)
		log_game("DYNAMIC: Too many living antags compared to living players ([antag_count] living antags, [player_count] living players, [max_traitors] max traitors)")
		return FALSE

	if (!prob(mode.threat_level))
		log_game("DYNAMIC: Random chance to roll autotraitor failed, it was a [mode.threat_level]% chance.")
		return FALSE

	return ..()

/datum/dynamic_ruleset/midround/autotraitor/trim_candidates()
	..()
	for(var/mob/living/player in living_players)
		if(issilicon(player)) // Your assigned role doesn't change when you are turned into a silicon.
			living_players -= player
		else if(is_centcom_level(player.z))
			living_players -= player // We don't autotator people in CentCom
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0))
			living_players -= player // We don't autotator people with roles already

/datum/dynamic_ruleset/midround/autotraitor/ready(forced = FALSE)
	if (required_candidates > living_players.len)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/autotraitor/execute()
	var/mob/M = pick(living_players)
	assigned += M
	living_players -= M
	var/datum/antagonist/traitor/newTraitor = new
	M.mind.add_antag_datum(newTraitor)
	return TRUE



//////////////////////////////////////////////
//                                          //
//                 FAMILIES                 //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/families
	name = "Family Head Aspirants"
	persistent = TRUE
	antag_flag = ROLE_FAMILIES
	protected_roles = list("Prisoner", "Head of Personnel")
	restricted_roles = list("Cyborg", "AI", "Security Officer", "Russian Officer", "Veteran", "Warden", "Detective", "Head of Security", "Captain", "Research Director", "Field Medic", "Exploration Crew")
	required_candidates = 9
	weight = 2
	cost = 19
	requirements = list(101,101,40,40,30,20,10,10,10,10)
	flags = HIGH_IMPACT_RULESET
	blocking_rules = list(/datum/dynamic_ruleset/roundstart/families)
	/// A reference to the handler that is used to run pre_execute(), execute(), etc..
	var/datum/gang_handler/handler

/datum/dynamic_ruleset/midround/families/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(issilicon(player))
			candidates -= player
		else if(is_centcom_level(player.z))
			candidates -= player
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0))
			candidates -= player
		else if(HAS_TRAIT(player, TRAIT_MINDSHIELD))
			candidates -= player


/datum/dynamic_ruleset/midround/families/ready(forced = FALSE)
	if (required_candidates > living_players.len)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/families/pre_execute()
	..()
	handler = new /datum/gang_handler(candidates,restricted_roles)
	handler.gang_balance_cap = clamp((indice_pop - 3), 2, 5) // gang_balance_cap by indice_pop: (2,2,2,2,2,3,4,5,5,5)
	handler.midround_ruleset = TRUE
	handler.use_dynamic_timing = TRUE
	return handler.pre_setup_analogue()

/datum/dynamic_ruleset/midround/families/execute()
	return handler.post_setup_analogue(TRUE)

/datum/dynamic_ruleset/midround/families/clean_up()
	QDEL_NULL(handler)
	..()

/datum/dynamic_ruleset/midround/families/rule_process()
	return handler.process_analogue()

/datum/dynamic_ruleset/midround/families/round_result()
	return handler.set_round_result_analogue()

//////////////////////////////////////////////
//                                          //
//         Malfunctioning AI                //
//                              		    //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/malf
	name = "Malfunctioning AI"
	antag_datum = /datum/antagonist/traitor
	antag_flag = ROLE_MALF
	enemy_roles = list("Russian Officer", "Hacker","Veteran", "Security Officer", "Warden","Detective","Head of Security", "Captain", "Scientist", "Chemist", "Research Director", "Chief Engineer", "Field Medic")
	exclusive_roles = list("AI")
	required_enemies = list(4,4,4,4,4,4,2,2,2,0)
	required_candidates = 1
	weight = 3
	cost = 35
	requirements = list(101,101,80,70,60,60,50,50,40,40)
	required_type = /mob/living/silicon/ai
	var/ion_announce = 33
	var/removeDontImproveChance = 10

/datum/dynamic_ruleset/midround/malf/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/player in candidates)
		if(!isAI(player))
			candidates -= player
		else if(is_centcom_level(player.z))
			candidates -= player
		else if(player.mind && (player.mind.special_role || player.mind.antag_datums?.len > 0))
			candidates -= player

/datum/dynamic_ruleset/midround/malf/execute()
	if(!candidates || !candidates.len)
		return FALSE
	var/mob/living/silicon/ai/M = pick_n_take(candidates)
	assigned += M.mind
	var/datum/antagonist/traitor/AI = new
	M.mind.special_role = antag_flag
	M.mind.add_antag_datum(AI)
	if(prob(ion_announce))
		priority_announce("Рядом со станцией обнаружена ионная буря. Пожалуйста, проверьте все оборудование, управляемое ИИ, на наличие ошибок.", "Аномальная тревога", ANNOUNCER_IONSTORM)
		if(prob(removeDontImproveChance))
			M.replace_random_law(generate_ion_law(), list(LAW_INHERENT, LAW_SUPPLIED, LAW_ION))
		else
			M.add_ion_law(generate_ion_law())
	return TRUE

//////////////////////////////////////////////
//                                          //
//              WIZARD (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/wizard
	name = "Волшебник"
	antag_datum = /datum/antagonist/wizard
	antag_flag = ROLE_WIZARD
	enemy_roles = list("Russian Officer", "Hacker","Veteran", "Security Officer", "Detective","Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 1
	cost = 20
	minimum_players = 35
	requirements = list(90,90,70,40,30,20,10,10,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_ghosts/wizard/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		return FALSE
	if(GLOB.wizardstart.len == 0)
		log_admin("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		message_admins("Cannot accept Wizard ruleset. Couldn't find any wizard spawn points.")
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/wizard/finish_setup(mob/new_character, index)
	..()
	new_character.forceMove(pick(GLOB.wizardstart))

//////////////////////////////////////////////
//                                          //
//               DEVIL                      //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/devil
	name = "Devil"
	antag_flag = ROLE_DEVIL
	antag_datum = /datum/antagonist/devil
	required_candidates = 1
	weight = 1
	cost = 15
	requirements = list(50,45,45,40,35,20,20,15,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/devil/execute()
	for(var/X in GLOB.xeno_spawn)
		var/turf/T = X
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += T
	if(!spawn_locs.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/devil/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Devil"
	player_mind.special_role = "Devil"
	add_devil(S, ascendable = TRUE)
	add_devil_objectives(player_mind,2)
	S.equip_to_slot_or_del(new /obj/item/clothing/under/rank/civilian/lawyer/black(S), ITEM_SLOT_ICLOTHING)
	S.equip_to_slot_or_del(new /obj/item/clothing/shoes/laceup(S), ITEM_SLOT_FEET)
	S.equip_to_slot_or_del(new /obj/item/storage/briefcase(S), ITEM_SLOT_HANDS)
	S.equip_to_slot_or_del(new /obj/item/pen(S), ITEM_SLOT_LPOCKET)
	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Devil by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a Devil by the midround ruleset.")
	return S

/datum/dynamic_ruleset/midround/from_ghosts/devil/proc/add_devil_objectives(datum/mind/devil_mind, quantity)
	var/list/validtypes = list(/datum/objective/devil/soulquantity, /datum/objective/devil/soulquality, /datum/objective/devil/sintouch, /datum/objective/devil/buy_target)
	var/datum/antagonist/devil/D = devil_mind.has_antag_datum(/datum/antagonist/devil)
	for(var/i = 1 to quantity)
		var/type = pick(validtypes)
		var/datum/objective/devil/objective = new type(null)
		objective.owner = devil_mind
		D.objectives += objective
		if(!istype(objective, /datum/objective/devil/buy_target))
			validtypes -= type
		else
			objective.find_target()


//////////////////////////////////////////////
//                                          //
//          NUCLEAR OPERATIVES (MIDROUND)   //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/nuclear
	name = "Nuclear Assault"
	antag_flag = ROLE_OPERATIVE
	antag_datum = /datum/antagonist/nukeop
	enemy_roles = list("AI", "Cyborg", "Russian Officer", "Hacker","Veteran", "Security Officer", "Warden","Detective","Head of Security", "Captain", "Field Medic")
	required_enemies = list(3,3,3,3,3,2,1,1,0,0)
	required_candidates = 5
	weight = 5
	cost = 35
	requirements = list(90,90,90,80,60,40,30,20,10,10)
	var/list/operative_cap = list(2,2,3,3,4,5,5,5,5,5)
	var/datum/team/nuclear/nuke_team
	flags = HIGH_IMPACT_RULESET

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/acceptable(population=0, threat=0)
	if (locate(/datum/dynamic_ruleset/roundstart/nuclear) in mode.executed_rules)
		return FALSE // Unavailable if nuke ops were already sent at roundstart
	indice_pop = min(operative_cap.len, round(living_players.len/5)+1)
	required_candidates = operative_cap[indice_pop]
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/nuclear/finish_setup(mob/new_character, index)
	new_character.mind.special_role = "Nuclear Operative"
	new_character.mind.assigned_role = "Nuclear Operative"
	if (index == 1) // Our first guy is the leader
		var/datum/antagonist/nukeop/leader/new_role = new
		nuke_team = new_role.nuke_team
		new_character.mind.add_antag_datum(new_role)
	else
		return ..()

//////////////////////////////////////////////
//                                          //
//              BLOB (GHOST)                //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/blob
	name = "Масса"
	antag_datum = /datum/antagonist/blob
	antag_flag = ROLE_BLOB
	enemy_roles = list("Russian Officer", "Hacker","Veteran", "Security Officer", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/from_ghosts/blob/generate_ruleset_body(mob/applicant)
	var/body = applicant.become_overmind()
	return body

//////////////////////////////////////////////
//                                          //
//           XENOMORPH (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph
	name = "Alien Infestation"
	antag_datum = /datum/antagonist/xeno
	antag_flag = ROLE_ALIEN
	enemy_roles = list("Russian Officer", "Hacker","Veteran", "Security Officer", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 3
	cost = 10
	requirements = list(101,101,101,70,50,40,20,15,10,10)
	repeatable = TRUE
	var/list/vents = list()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/execute()
	// 50% chance of being incremented by one
	required_candidates += prob(50)
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		if(QDELETED(temp_vent))
			continue
		if(is_station_level(temp_vent.loc.z) && !temp_vent.welded)
			var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
			if(!temp_vent_parent)
				continue // No parent vent
			// Stops Aliens getting stuck in small networks.
			// See: Security, Virology
			if(temp_vent_parent.other_atmosmch.len > 20)
				vents += temp_vent
	if(!vents.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/xenomorph/generate_ruleset_body(mob/applicant)
	var/obj/vent = pick_n_take(vents)
	var/mob/living/carbon/alien/larva/new_xeno = new(vent.loc)
	new_xeno.key = applicant.key
	message_admins("[ADMIN_LOOKUPFLW(new_xeno)] has been made into an alien by the midround ruleset.")
	log_game("DYNAMIC: [key_name(new_xeno)] was spawned as an alien by the midround ruleset.")
	return new_xeno

//////////////////////////////////////////////
//                                          //
//           NIGHTMARE (GHOST)              //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/nightmare
	name = "Кошмар"
	antag_datum = /datum/antagonist/nightmare
	antag_flag = "Nightmare"
	antag_flag_override = ROLE_ALIEN
	enemy_roles = list("Russian Officer", "Hacker","Veteran", "Security Officer", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 3
	cost = 10
	requirements = list(101,101,101,70,50,40,20,15,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/execute()
	for(var/X in GLOB.xeno_spawn)
		var/turf/T = X
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += T
	if(!spawn_locs.len)
		return FALSE
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/nightmare/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/carbon/human/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Nightmare"
	player_mind.special_role = "Nightmare"
	player_mind.add_antag_datum(/datum/antagonist/nightmare)
	S.set_species(/datum/species/shadow/nightmare)

	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Nightmare by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a Nightmare by the midround ruleset.")
	return S

//////////////////////////////////////////////
//                                          //
//           SPACE DRAGON (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon
	name = "Космический дракон"
	antag_datum = /datum/antagonist/space_dragon
	antag_flag = "Space Dragon"
	antag_flag_override = ROLE_SPACE_DRAGON
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/execute()
	for(var/obj/effect/landmark/carpspawn/C in GLOB.landmarks_list)
		spawn_locs += (C.loc)
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	. = ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_dragon/generate_ruleset_body(mob/applicant)
	var/datum/mind/player_mind = new /datum/mind(applicant.key)
	player_mind.active = TRUE

	var/mob/living/simple_animal/hostile/space_dragon/S = new (pick(spawn_locs))
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Space Dragon"
	player_mind.special_role = "Space Dragon"
	player_mind.add_antag_datum(/datum/antagonist/space_dragon)

	playsound(S, 'sound/magic/ethereal_exit.ogg', 50, TRUE, -1)
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a Space Dragon by the midround ruleset.")
	log_game("DYNAMIC: [key_name(S)] was spawned as a Space Dragon by the midround ruleset.")
	priority_announce("Большой поток органической энергии был зарегистрирован около [station_name()], приготовьтесь.", "Биологическая тревога")
	return S

//////////////////////////////////////////////
//                                          //
//           ABDUCTORS    (GHOST)           //
//                                          //
//////////////////////////////////////////////
#define ABDUCTOR_MAX_TEAMS 4

/datum/dynamic_ruleset/midround/from_ghosts/abductors
	name = "Abductors"
	antag_flag = "Abductor"
	antag_flag_override = ROLE_ABDUCTOR
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 2
	weight = 4
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE
	var/datum/team/abductor_team/new_team

/datum/dynamic_ruleset/midround/from_ghosts/abductors/ready(forced = FALSE)
	if (required_candidates > (dead_players.len + list_observers.len))
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/abductors/finish_setup(mob/new_character, index)
	if (index == 1) // Our first guy is the scientist.  We also initialize the team here as well since this should only happen once per pair of abductors.
		new_team = new
		if(new_team.team_number > ABDUCTOR_MAX_TEAMS)
			return MAP_ERROR
		var/datum/antagonist/abductor/scientist/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)
	else // Our second guy is the agent, team is already created, don't need to make another one.
		var/datum/antagonist/abductor/agent/new_role = new
		new_character.mind.add_antag_datum(new_role, new_team)

#undef ABDUCTOR_MAX_TEAMS

//////////////////////////////////////////////
//                                          //
//            SWARMERS    (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/swarmers
	name = "Паразиты"
	antag_datum = /datum/antagonist/swarmer
	antag_flag = "Swarmer"
	antag_flag_override = ROLE_ALIEN
	required_type = /mob/dead/observer
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/swarmers/execute()
	var/list/spawn_locs = list()
	for(var/x in GLOB.xeno_spawn)
		var/turf/spawn_turf = x
		var/light_amount = spawn_turf.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += spawn_turf
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found in GLOB.xeno_spawn, aborting swarmer spawning...")
		return MAP_ERROR
	var/obj/structure/swarmer_beacon/new_beacon = new(pick(spawn_locs))
	log_game("A Swarmer Beacon was spawned via Dynamic Mode.")
	notify_ghosts("\A Swarmer Beacon has spawned!", source = new_beacon, action = NOTIFY_ORBIT, flashwindow = FALSE, header = "Swarmer Beacon Spawned")
	return ..()

//////////////////////////////////////////////
//                                          //
//            SPACE NINJA (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja
	name = "Космический ниндзя"
	antag_datum = /datum/antagonist/ninja
	antag_flag = "Space Ninja"
	antag_flag_override = ROLE_NINJA
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/execute()
	for(var/obj/effect/landmark/carpspawn/carp_spawn in GLOB.landmarks_list)
		if(!isturf(carp_spawn.loc))
			stack_trace("Carp spawn found not on a turf: [carp_spawn.type] on [isnull(carp_spawn.loc) ? "null" : carp_spawn.loc.type]")
			continue
		spawn_locs += carp_spawn.loc
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/space_ninja/generate_ruleset_body(mob/applicant)
	var/mob/living/carbon/human/ninja = create_space_ninja(pick(spawn_locs))
	ninja.key = applicant.key
	ninja.mind.add_antag_datum(/datum/antagonist/ninja)

	message_admins("[ADMIN_LOOKUPFLW(ninja)] has been made into a Space Ninja by the midround ruleset.")
	log_game("DYNAMIC: [key_name(ninja)] was spawned as a Space Ninja by the midround ruleset.")
	return ninja

//////////////////////////////////////////////
//                                          //
//            SPIDERS     (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/spiders
	name = "Spiders"
	antag_flag = "Spider"
	antag_flag_override = ROLE_ALIEN
	required_type = /mob/dead/observer
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 0
	weight = 3
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE
	var/spawncount = 2

/datum/dynamic_ruleset/midround/spiders/execute()
	create_midwife_eggs(spawncount)
	return ..()

//////////////////////////////////////////////
//                                          //
//            CLOWN APOSTLE (GHOST)           //
//                                          //
//////////////////////////////////////////////

/datum/dynamic_ruleset/midround/from_ghosts/clown_apostle
	name = "Апостол Хонкоматери"
	enemy_roles = list("Security Officer", "Russian Officer", "Hacker", "Veteran", "Detective", "Head of Security", "Captain", "Field Medic")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 10
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE
	var/list/spawn_locs = list()

/datum/dynamic_ruleset/midround/from_ghosts/clown_apostle/execute()
	for(var/X in GLOB.xeno_spawn)
		var/turf/T = X
		var/light_amount = T.get_lumcount()
		if(light_amount < SHADOW_SPECIES_LIGHT_THRESHOLD)
			spawn_locs += T
	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/clown_apostle/generate_ruleset_body(mob/applicant)
	var/mob/living/simple_animal/hostile/clown/mutant/glutton/apostle = new(pick(spawn_locs))
	apostle.key = applicant.key

	message_admins("[ADMIN_LOOKUPFLW(apostle)] has been made into a Clown Apostle by the midround ruleset.")
	log_game("DYNAMIC: [key_name(apostle)] was spawned as a Clown Apostle by the midround ruleset.")
	return apostle

/// Obsessed ruleset
/datum/dynamic_ruleset/midround/obsessed
	name = "Obsessed"
	antag_datum = /datum/antagonist/obsessed
	antag_flag = ROLE_OBSESSED
	restricted_roles = list("Cyborg", "AI", "Positronic Brain")
	enemy_roles = list("Security Officer", "Detective", "Head of Security", "Captain")
	required_enemies = list(2,2,1,1,1,1,1,0,0,0)
	required_candidates = 1
	weight = 4
	cost = 3 // Doesn't have the same impact on rounds as revenants, dragons, sentient disease (10) or syndicate infiltrators (5).
	requirements = list(101,101,101,80,60,50,30,20,10,10)
	repeatable = TRUE

/datum/dynamic_ruleset/midround/obsessed/trim_candidates()
	..()
	candidates = living_players
	for(var/mob/living/carbon/human/candidate in candidates)
		if( \
			!candidate.getorgan(/obj/item/organ/brain) \
			|| candidate.mind.has_antag_datum(/datum/antagonist/obsessed) \
			|| candidate.stat == DEAD \
			|| !(ROLE_OBSESSED in candidate.client?.prefs?.be_special) \
			|| !candidate.mind.assigned_role \
		)
			candidates -= candidate

/datum/dynamic_ruleset/midround/obsessed/execute()
	if(!candidates || !candidates.len)
		return FALSE
	var/mob/living/carbon/human/obsessed = pick_n_take(candidates)
	obsessed.gain_trauma(/datum/brain_trauma/special/obsessed)
	message_admins("[ADMIN_LOOKUPFLW(obsessed)] has been made Obsessed by the midround ruleset.")
	log_game("[key_name(obsessed)] was made Obsessed by the midround ruleset.")
	return ..()
