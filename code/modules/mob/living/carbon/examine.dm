/mob/living/carbon/examine(mob/user)
	var/t_on 	= ru_who(TRUE)
	var/t_ego 	= ru_ego()
	var/t_a 	= ru_a()

	. = list("<span class='info'>Это же [icon2html(src, user)] <EM>[src]</EM>!<hr>")
	var/list/obscured = check_obscured_slots()

	if (handcuffed)
		. += "<span class='warning'>[t_on] [icon2html(handcuffed, user)] в наручниках!</span>\n"
	if (head)
		. += "На голове у н[t_ego] [head.get_examine_string(user)].\n"
	if(wear_mask && !(obscured & ITEM_SLOT_MASK))
		. += "На [t_ego] лице [wear_mask.get_examine_string(user)].\n"
	if(wear_neck && !(obscured & ITEM_SLOT_NECK))
		. += "На шее у н[t_ego] [wear_neck.get_examine_string(user)].\n"

	for(var/obj/item/I in held_items)
		if(!(I.item_flags & ABSTRACT))
			. += "В [t_ego] [get_held_index_name(get_held_index_of_item(I))] он[t_a] держит [I.get_examine_string(user)].\n"

	if (back)
		. += "На [t_ego] спине [back.get_examine_string(user)].\n"
	var/appears_dead = FALSE
	if (stat == DEAD)
		appears_dead = TRUE
		if(getorgan(/obj/item/organ/brain))
			. += "<span class='deadsay'>[t_on] не реагирует на происходящее вокруг; нет признаков жизни...</span>\n"
		else if(get_bodypart(BODY_ZONE_HEAD))
			. += "<span class='deadsay'>Похоже, что у н[t_ego] нет мозга...</span>\n"

	var/list/msg = list("<span class='warning'>")
	var/list/missing = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	var/list/disabled = list()
	for(var/X in bodyparts)
		var/obj/item/bodypart/BP = X
		if(BP.bodypart_disabled)
			disabled += BP
		missing -= BP.body_zone
		for(var/obj/item/I in BP.embedded_objects)
			if(I.isEmbedHarmless())
				msg += "<B>Из [t_ego] [BP.name] торчит [icon2html(I, user)] [I]!</B>\n"
			else
				msg += "<B>У н[t_ego] застрял [icon2html(I, user)] [I] в [BP.name]!</B>\n"
		for(var/i in BP.wounds)
			var/datum/wound/W = i
			msg += "[W.get_examine_description(user)]\n"

	for(var/X in disabled)
		var/obj/item/bodypart/BP = X
		var/damage_text
		if(!(BP.get_damage(include_stamina = FALSE) >= BP.max_damage)) //Stamina is disabling the limb
			damage_text = "вялая"
		else
			damage_text = (BP.brute_dam >= BP.burn_dam) ? BP.heavy_brute_msg : BP.heavy_burn_msg
		msg += "<B>[capitalize(t_ego)] [BP.name] [damage_text]!</B>\n"

	for(var/t in missing)
		if(t==BODY_ZONE_HEAD)
			msg += "<span class='deadsay'><B>[ru_ego(TRUE)] [parse_zone(t)] отсутствует!</B></span>\n"
			continue
		msg += "<span class='warning'><B>[ru_ego(TRUE)] [parse_zone(t)] отсутствует!</B></span>\n"

	var/temp = getBruteLoss()
	if(!(user == src && src.hal_screwyhud == SCREWYHUD_HEALTHY)) //fake healthy
		if(temp)
			if (temp < 25)
				msg += "[t_on] имеет незначительные ушибы.\n"
			else if (temp < 50)
				msg += "[t_on] <b>весьма серьезно</b> ранен[t_a]!\n"
			else if (temp < 75)
				msg += "[t_on] <b>тяжело</b> ранен[t_a]!\n"
			else
				msg += "<B>[t_on] смертельно ранен[t_a]!</B>\n"

		temp = getFireLoss()
		if(temp)
			if (temp < 25)
				msg += "[t_on] немного подгорел[t_a].\n"
			else if (temp < 50)
				msg += "[t_on] имеет <b>серьёзные</b> ожоги!\n"
			else if (temp < 75)
				msg += "[t_on] имеет <b>тяжелые</b> ожоги!\n"
			else
				msg += "<B>[t_on] имеет смертельные ожоги!</B>\n"

		temp = getCloneLoss()
		if(temp)
			if(temp < 25)
				msg += "[t_on] имеет незначительные подтёки на теле.\n"
			else if(temp < 50)
				msg += "[t_on] имеет <b>обвисшую</b> кожу на большей части тела!\n"
			else
				msg += "<b>[t_on] имеет тело состоящее из кусков свисающей плоти!</b>\n"

	if(HAS_TRAIT(src, TRAIT_DUMB))
		msg += "[t_on] имеет глупое выражение лица.\n"

	if(fire_stacks > 0)
		msg += "[t_on] в чем-то горючем.\n"
	if(fire_stacks < 0)
		msg += "[t_on] выглядит мокро.\n"

	if(pulledby?.grab_state)
		msg += "[t_on] удерживается захватом [pulledby].\n"

	var/scar_severity = 0
	for(var/i in all_scars)
		var/datum/scar/S = i
		if(S.is_visible(user))
			scar_severity += S.severity

	switch(scar_severity)
		if(1 to 4)
			msg += "\n<span class='smallnoticeital'>[t_on] похоже имеет шрамы... Стоит присмотреться, чтобы разглядеть ещё.</span>\n"
		if(5 to 8)
			msg += "\n<span class='notice'><i>[t_on] имеет несколько серьёзных шрамов... Стоит присмотреться, чтобы разглядеть ещё.</i></span>\n"
		if(9 to 11)
			msg += "\n<span class='notice'><b><i>[t_on] имеет множество ужасных шрамов... Стоит присмотреться, чтобы разглядеть ещё.</i></b></span>\n"
		if(12 to INFINITY)
			msg += "\n<span class='notice'><b><i>[t_on] имеет разорванное в хлам тело состоящее из шрамов... Стоит присмотреться, чтобы разглядеть ещё?</i></b></span>\n"

	msg += "</span>"

	. += msg.Join("")

	if(!appears_dead)
		switch(stat)
			if(SOFT_CRIT)
				. += "[t_on] вот-вот потеряет сознание.\n"
			if(UNCONSCIOUS, HARD_CRIT)
				. += "[t_on] без сознания.\n"

	var/trait_exam = common_trait_examine()
	if (!isnull(trait_exam))
		. += trait_exam

	var/datum/component/mood/mood = src.GetComponent(/datum/component/mood)
	if(mood)
		switch(mood.shown_mood)
			if(-INFINITY to MOOD_LEVEL_SAD4)
				. += "[t_on] выглядит убито, будто сейчас расплачется."
			if(MOOD_LEVEL_SAD4 to MOOD_LEVEL_SAD3)
				. += "[t_on] выглядит расстроено."
			if(MOOD_LEVEL_SAD3 to MOOD_LEVEL_SAD2)
				. += "[t_on] выглядит немного не в себе."
			if(MOOD_LEVEL_HAPPY2 to MOOD_LEVEL_HAPPY3)
				. += "[t_on] выглядит немного на веселе."
			if(MOOD_LEVEL_HAPPY3 to MOOD_LEVEL_HAPPY4)
				. += "[t_on] выглядит очень весело."
			if(MOOD_LEVEL_HAPPY4 to INFINITY)
				. += "[t_on] в экстазе."
	. += "</span>"

	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, .)

/mob/living/carbon/examine_more(mob/user)
	if(!all_scars)
		return ..()

	var/list/visible_scars
	for(var/i in all_scars)
		var/datum/scar/S = i
		if(S.is_visible(user))
			LAZYADD(visible_scars, S)

	if(!visible_scars)
		return ..()

	var/msg = list("<span class='notice'><i>Всматриваюсь в <b>[src]</b> и замечаю следующее...</i></span>\n")
	for(var/i in visible_scars)
		var/datum/scar/S = i
		var/scar_text = S.get_examine_description(user)
		if(scar_text)
			msg += "[scar_text]\n"

	return msg
