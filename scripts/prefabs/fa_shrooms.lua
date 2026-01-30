--------------------------------------------------
-- assets
--------------------------------------------------

local redshroomassets =
{
    Asset("ANIM", "anim/fa_redshroom.zip"),
}
local pinkshroomassets =
{
    Asset("ANIM", "anim/fa_pinkshroom.zip"),
}
local greenshroomassets =
{
    Asset("ANIM", "anim/fa_greenshroom.zip"),
}

local redshroomcapassets =
{
    Asset("ANIM", "anim/fa_redshroomcap.zip"),
}
local pinkshroomcapassets =
{
    Asset("ANIM", "anim/fa_pinkshroomcap.zip"),
}
local greenshroomcapassets =
{
    Asset("ANIM", "anim/fa_greenshroomcap.zip"),
}

local prefabs = {}

--------------------------------------------------
-- pickable 回调
--------------------------------------------------

local function onregenfn(inst)
    inst.AnimState:PlayAnimation("idle", true)
    inst.Light:Enable(true)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
    inst.Light:Enable(false)
end

local function onpickedfn(inst)
    inst.AnimState:PushAnimation("picked")
    inst.Light:Enable(false)
end

local function GetStatus(inst)
    if inst.components.pickable
        and inst.components.pickable.canbepicked
        and inst.components.pickable.caninteractwith then
        return "GENERIC"
    else
        return "PICKED"
    end
end

local function ondig(inst, worker)
    if inst.components.lootdropper then
        if inst.components.pickable
            and inst.components.pickable.canbepicked then
            -- 未采摘：cap + dug
            inst.components.lootdropper:SpawnLootPrefab(inst.prefab .. "cap")
        end

        -- 不论是否采摘，都掉 dug
        inst.components.lootdropper:SpawnLootPrefab(inst.prefab .. "_dug")
    end

    inst:Remove()
end


--------------------------------------------------
-- dug 物品（可部署）
--------------------------------------------------

local function make_dug_fn(plantname, buildname)

    local function ondeploy(inst, pt, deployer)
        local plant = SpawnPrefab(plantname)
        if plant then
            plant.Transform:SetPosition(pt.x, pt.y, pt.z)
			plant.components.pickable:MakeEmpty()  -- 立即变已采摘
            inst:Remove()
        end
    end

    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(buildname)
        inst.AnimState:SetBuild(buildname)
        inst.AnimState:PlayAnimation("picked")
		
		inst:AddComponent("stackable")
		inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.atlasname =
            "images/inventoryimages/fa_inventoryimages.xml"
		inst.components.inventoryitem.imagename =
            "shroom_dug"
		inst.components.inventoryitem.imagenameoverride = plantname
		
        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = ondeploy

        return inst
    end
end

--------------------------------------------------
-- 蘑菇本体
--------------------------------------------------

local function shroomfn(name)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    MakeObstaclePhysics(inst, 0.3)

    local light = inst.entity:AddLight()
    light:SetFalloff(1)
    light:SetIntensity(0.4)
    light:SetRadius(3)
    light:SetColour(255/255, 150/255, 150/255)
    light:Enable(true)

    inst.AnimState:SetBank(name)
    inst.AnimState:SetBuild(name)
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetRayTestOnBB(true)

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("pickable")
    inst.components.pickable.picksound =
        "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp(name .. "cap",
        TUNING.GRASS_REGROW_TIME)
    inst.components.pickable:SetOnPickedFn(onpickedfn)
    inst.components.pickable:SetOnRegenFn(onregenfn)
    inst.components.pickable:SetMakeEmptyFn(makeemptyfn)

    -- ★ 挖掘移植
    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(ondig)

    return inst
end

--------------------------------------------------
-- cap
--------------------------------------------------

local function capfn(name)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(name)
    inst.AnimState:SetBuild(name)
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname =
        "images/inventoryimages/fa_inventoryimages.xml"

    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 1
    inst.components.edible.hungervalue = 1
    inst.components.edible.sanityvalue = 1
    inst.components.edible.foodtype = "VEGGIE"

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

--------------------------------------------------
-- prefab
--------------------------------------------------

return
    Prefab("common/fa_redshroomcap",
        function() return capfn("fa_redshroomcap") end,
        redshroomcapassets, prefabs),

    Prefab("common/fa_pinkshroomcap",
        function() return capfn("fa_pinkshroomcap") end,
        pinkshroomcapassets, prefabs),

    Prefab("common/fa_greenshroomcap",
        function() return capfn("fa_greenshroomcap") end,
        greenshroomcapassets, prefabs),

    Prefab("common/fa_redshroom",
        function() return shroomfn("fa_redshroom") end,
        redshroomassets, prefabs),

    Prefab("common/fa_pinkshroom",
        function() return shroomfn("fa_pinkshroom") end,
        pinkshroomassets, prefabs),

    Prefab("common/fa_greenshroom",
        function() return shroomfn("fa_greenshroom") end,
        greenshroomassets, prefabs),

    Prefab("common/fa_redshroom_dug",
        make_dug_fn("fa_redshroom", "fa_redshroom"),
        redshroomassets, prefabs),

    Prefab("common/fa_pinkshroom_dug",
        make_dug_fn("fa_pinkshroom", "fa_pinkshroom"),
        pinkshroomassets, prefabs),

    Prefab("common/fa_greenshroom_dug",
        make_dug_fn("fa_greenshroom", "fa_greenshroom"),
        greenshroomassets, prefabs)
