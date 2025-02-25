
/////AUGMENTATION SURGERIES//////


//SURGERY STEPS

/datum/surgery_step/replace_limb
	name = "Замените часть тела"
	implements = list(/obj/item/bodypart = 100, /obj/item/organ_storage = 100)
	time = 32
	var/obj/item/bodypart/L = null // L because "limb"


/datum/surgery_step/replace_limb/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(NOAUGMENTS in target.dna.species.species_traits)
		to_chat(user, span_warning("[target] не может быть аугментирована!"))
		return -1
	if(istype(tool, /obj/item/organ_storage) && istype(tool.contents[1], /obj/item/bodypart))
		tool = tool.contents[1]
	var/obj/item/bodypart/aug = tool
	if(aug.status != BODYPART_ROBOTIC)
		to_chat(user, span_warning("Это не так работает, глупый!"))
		return -1
	if(aug.body_zone != target_zone)
		to_chat(user, span_warning("Кажется [tool] не подходит для [parse_zone(target_zone)]."))
		return -1
	L = surgery.operated_bodypart
	if(L)
		display_results(user, target, span_notice("Вы начинаете аугментировать [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)]...") ,
			span_notice("[user] начинает аугментировать [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)] при помощи [aug].") ,
			span_notice("[user] начинает аугментировать [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)]."))
		display_pain(target, "Чувствую ужасную боль в [parse_zone(user.zone_selected)][skloname(target.name, DATELNI, target.gender)]!")
	else
		user.visible_message(span_notice("[user] пытается найти [parse_zone(user.zone_selected)] [target].") , span_notice("Вы пытаетесь найти [parse_zone(user.zone_selected)] [target]..."))


//ACTUAL SURGERIES

/datum/surgery/augmentation
	name = "Аугментация"
	steps = list(/datum/surgery_step/incise, /datum/surgery_step/clamp_bleeders, /datum/surgery_step/retract_skin, /datum/surgery_step/replace_limb)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_R_ARM,BODY_ZONE_L_ARM,BODY_ZONE_R_LEG,BODY_ZONE_L_LEG,BODY_ZONE_CHEST,BODY_ZONE_HEAD)
	requires_real_bodypart = TRUE

//SURGERY STEP SUCCESSES

/datum/surgery_step/replace_limb/success(mob/user, mob/living/carbon/target, target_zone, obj/item/bodypart/tool, datum/surgery/surgery, default_display_results = FALSE)
	if(L)
		if(istype(tool, /obj/item/organ_storage))
			tool.icon_state = initial(tool.icon_state)
			tool.desc = initial(tool.desc)
			tool.cut_overlays()
			tool = tool.contents[1]
		if(istype(tool) && user.temporarilyRemoveItemFromInventory(tool))
			tool.replace_limb(target, TRUE)
		display_results(user, target, span_notice("Вы успешно аугментировали [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)].") ,
			span_notice("[user] успешно аугментировал [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)] при помощи [tool]!") ,
			span_notice("[user] успешно аугментировал [parse_zone(user.zone_selected)] [skloname(target.name, RODITELNI, target.gender)]!"))
		log_combat(user, target, "аугментировал", addition="дав ему новую [parse_zone(target_zone)] INTENT: [uppertext(user.a_intent)]")
		display_pain(target, "Моя [parse_zone(target_zone)] приходит в чувство с необычным ощущением!", mechanical_surgery = TRUE)
	else
		to_chat(user, span_warning("[target] не имеет органики на [parse_zone(target_zone)]!"))
	return ..()
