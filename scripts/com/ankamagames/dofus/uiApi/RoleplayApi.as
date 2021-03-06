package com.ankamagames.dofus.uiApi
{
   import com.ankamagames.atouin.managers.EntitiesManager;
   import com.ankamagames.berilia.enums.StrataEnum;
   import com.ankamagames.berilia.interfaces.IApi;
   import com.ankamagames.berilia.managers.TooltipManager;
   import com.ankamagames.berilia.managers.UiModuleManager;
   import com.ankamagames.berilia.types.LocationEnum;
   import com.ankamagames.berilia.types.data.UiModule;
   import com.ankamagames.dofus.datacenter.almanax.AlmanaxCalendar;
   import com.ankamagames.dofus.datacenter.bonus.Bonus;
   import com.ankamagames.dofus.datacenter.bonus.MonsterDropChanceBonus;
   import com.ankamagames.dofus.datacenter.bonus.MonsterStarRateBonus;
   import com.ankamagames.dofus.datacenter.bonus.MonsterXPBonus;
   import com.ankamagames.dofus.datacenter.monsters.Monster;
   import com.ankamagames.dofus.datacenter.monsters.MonsterRace;
   import com.ankamagames.dofus.datacenter.spells.Spell;
   import com.ankamagames.dofus.datacenter.world.MapPosition;
   import com.ankamagames.dofus.internalDatacenter.communication.ChatBubble;
   import com.ankamagames.dofus.internalDatacenter.spells.SpellWrapper;
   import com.ankamagames.dofus.kernel.Kernel;
   import com.ankamagames.dofus.logic.game.common.frames.EmoticonFrame;
   import com.ankamagames.dofus.logic.game.common.frames.SpellInventoryManagementFrame;
   import com.ankamagames.dofus.logic.game.common.frames.WorldFrame;
   import com.ankamagames.dofus.logic.game.common.managers.AlmanaxManager;
   import com.ankamagames.dofus.logic.game.common.managers.PlayedCharacterManager;
   import com.ankamagames.dofus.logic.game.common.misc.DofusEntities;
   import com.ankamagames.dofus.logic.game.roleplay.frames.RoleplayContextFrame;
   import com.ankamagames.dofus.logic.game.roleplay.frames.RoleplayEntitiesFrame;
   import com.ankamagames.dofus.logic.game.roleplay.frames.RoleplayInteractivesFrame;
   import com.ankamagames.dofus.logic.game.roleplay.frames.ZaapFrame;
   import com.ankamagames.dofus.logic.game.roleplay.managers.RoleplayManager;
   import com.ankamagames.dofus.logic.game.roleplay.types.RoleplaySpellCastProvider;
   import com.ankamagames.dofus.network.ProtocolConstantsEnum;
   import com.ankamagames.dofus.network.types.game.context.EntityDispositionInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.AlternativeMonstersInGroupLightInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GameRolePlayGroupMonsterInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GameRolePlayGroupMonsterWaveInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GameRolePlayNamedActorInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GameRolePlayNpcInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GroupMonsterStaticInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GroupMonsterStaticInformationsWithAlternatives;
   import com.ankamagames.dofus.network.types.game.context.roleplay.MonsterInGroupInformations;
   import com.ankamagames.dofus.network.types.game.context.roleplay.MonsterInGroupLightInformations;
   import com.ankamagames.dofus.scripts.SpellScriptManager;
   import com.ankamagames.dofus.types.entities.AnimatedCharacter;
   import com.ankamagames.dofus.types.sequences.AddGfxEntityStep;
   import com.ankamagames.jerakine.data.XmlConfig;
   import com.ankamagames.jerakine.entities.interfaces.IDisplayable;
   import com.ankamagames.jerakine.entities.interfaces.IEntity;
   import com.ankamagames.jerakine.interfaces.IRectangle;
   import com.ankamagames.jerakine.logger.Log;
   import com.ankamagames.jerakine.logger.Logger;
   import com.ankamagames.jerakine.sequencer.ISequencable;
   import com.ankamagames.jerakine.sequencer.ISequencer;
   import com.ankamagames.jerakine.sequencer.SerialSequencer;
   import com.ankamagames.jerakine.types.Callback;
   import com.ankamagames.jerakine.types.positions.MapPoint;
   import com.ankamagames.tiphon.sequence.PlayAnimationStep;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   
   [InstanciedApi]
   public class RoleplayApi implements IApi
   {
      
      private static var _mapApi:MapApi = new MapApi();
       
      
      private var _module:UiModule;
      
      protected var _log:Logger;
      
      public function RoleplayApi()
      {
         this._log = Log.getLogger(getQualifiedClassName(RoleplayApi));
         super();
      }
      
      private function get roleplayEntitiesFrame() : RoleplayEntitiesFrame
      {
         return Kernel.getWorker().getFrame(RoleplayEntitiesFrame) as RoleplayEntitiesFrame;
      }
      
      private function get roleplayInteractivesFrame() : RoleplayInteractivesFrame
      {
         return Kernel.getWorker().getFrame(RoleplayInteractivesFrame) as RoleplayInteractivesFrame;
      }
      
      private function get spellInventoryManagementFrame() : SpellInventoryManagementFrame
      {
         return Kernel.getWorker().getFrame(SpellInventoryManagementFrame) as SpellInventoryManagementFrame;
      }
      
      private function get roleplayEmoticonFrame() : EmoticonFrame
      {
         return Kernel.getWorker().getFrame(EmoticonFrame) as EmoticonFrame;
      }
      
      private function get zaapFrame() : ZaapFrame
      {
         return Kernel.getWorker().getFrame(ZaapFrame) as ZaapFrame;
      }
      
      private function get worldFrame() : WorldFrame
      {
         return Kernel.getWorker().getFrame(WorldFrame) as WorldFrame;
      }
      
      [ApiData(name="module")]
      public function set module(value:UiModule) : void
      {
         this._module = value;
      }
      
      [Trusted]
      public function destroy() : void
      {
         this._module = null;
      }
      
      [Untrusted]
      public function getTotalFightOnCurrentMap() : uint
      {
         return this.roleplayEntitiesFrame.fightNumber;
      }
      
      [Untrusted]
      public function getSpellToForgetList() : Array
      {
         var spell:* = null;
         var spellList:Array = new Array();
         for each(spell in PlayedCharacterManager.getInstance().spellsInventory)
         {
            if(spell.spellLevel > 1)
            {
               spellList.push(spell);
            }
         }
         return spellList;
      }
      
      [Untrusted]
      public function getEmotesList() : Array
      {
         var emotes:Array = this.roleplayEmoticonFrame.emotesList;
         return emotes;
      }
      
      [Untrusted]
      public function getUsableEmotesList() : Array
      {
         return this.roleplayEmoticonFrame.emotes;
      }
      
      [Untrusted]
      public function getSpawnMap() : Number
      {
         return this.zaapFrame.spawnMapId;
      }
      
      [Trusted]
      public function getEntitiesOnCell(cellId:int) : Array
      {
         return EntitiesManager.getInstance().getEntitiesOnCell(cellId);
      }
      
      [Trusted]
      public function getPlayersIdOnCurrentMap() : Array
      {
         return this.roleplayEntitiesFrame.playersId;
      }
      
      [Trusted]
      public function getMerchants() : Array
      {
         return this.roleplayEntitiesFrame.merchants;
      }
      
      [Trusted]
      public function getPlayerIsInCurrentMap(playerId:Number) : Boolean
      {
         return this.roleplayEntitiesFrame.playersId.indexOf(playerId) != -1;
      }
      
      [Trusted]
      public function isUsingInteractive() : Boolean
      {
         if(!this.roleplayInteractivesFrame)
         {
            return false;
         }
         return this.roleplayInteractivesFrame.usingInteractive;
      }
      
      [Untrusted]
      public function getFight(id:int) : Object
      {
         return this.roleplayEntitiesFrame.fights[id];
      }
      
      [Trusted]
      public function putEntityOnTop(entity:AnimatedCharacter) : void
      {
         RoleplayManager.getInstance().putEntityOnTop(entity);
      }
      
      [Trusted]
      public function playGfx(gfxId:uint, cellId:uint) : void
      {
         var seq:ISequencer = new SerialSequencer();
         seq.addStep(new AddGfxEntityStep(gfxId,cellId,0,0,0,null,null,true));
         seq.start();
      }
      
      [Untrusted]
      public function getEntityInfos(entity:Object) : Object
      {
         var roleplayContextFrame:RoleplayContextFrame = Kernel.getWorker().getFrame(RoleplayContextFrame) as RoleplayContextFrame;
         return roleplayContextFrame.entitiesFrame.getEntityInfos(entity.id);
      }
      
      [Untrusted]
      public function getEntityByName(name:String) : Object
      {
         var entity:* = null;
         var infos:* = null;
         var roleplayContextFrame:RoleplayContextFrame = Kernel.getWorker().getFrame(RoleplayContextFrame) as RoleplayContextFrame;
         for each(entity in EntitiesManager.getInstance().entities)
         {
            infos = roleplayContextFrame.entitiesFrame.getEntityInfos(entity.id) as GameRolePlayNamedActorInformations;
            if(infos && name == infos.name)
            {
               return entity;
            }
         }
         return null;
      }
      
      [Trusted]
      public function switchButtonWrappers(btnWrapper1:Object, btnWrapper2:Object) : void
      {
         var indexT:int = btnWrapper2.position;
         var indexS:int = btnWrapper1.position;
         btnWrapper2.setPosition(indexS);
         btnWrapper1.setPosition(indexT);
      }
      
      [Trusted]
      public function setButtonWrapperActivation(btnWrapper:Object, active:Boolean, description:String = "") : void
      {
         btnWrapper.active = active;
         var disabledTxtColor:String = (XmlConfig.getInstance().getEntry("colors.tooltip.text.disabled") as String).replace("0x","#");
         if(btnWrapper.active)
         {
            btnWrapper.name = btnWrapper.name.replace("<font color=\'" + disabledTxtColor + "\'>","").replace("</font>","");
         }
         else if(btnWrapper.name.charAt(0) != "<")
         {
            btnWrapper.name = btnWrapper.name.replace(btnWrapper.name,"<font color=\'" + disabledTxtColor + "\'>" + btnWrapper.name + "</font>");
         }
         if(description)
         {
            btnWrapper.description = description;
         }
      }
      
      [Trusted]
      public function playEntityAnimation(npcID:int, animationName:String) : void
      {
         var abstractEntitiesFrame:* = null;
         var list:* = null;
         var npc:* = null;
         var ac:* = null;
         var seq:* = null;
         try
         {
            abstractEntitiesFrame = Kernel.getWorker().getFrame(RoleplayEntitiesFrame) as RoleplayEntitiesFrame;
            list = abstractEntitiesFrame.getEntitiesDictionnary();
            if(list.length <= 0)
            {
               return;
            }
            for each(npc in list)
            {
               if(npc is GameRolePlayNpcInformations && npc.npcId == npcID)
               {
                  ac = DofusEntities.getEntity(GameRolePlayNpcInformations(npc).contextualId) as AnimatedCharacter;
                  seq = new SerialSequencer();
                  seq.addStep(new PlayAnimationStep(ac,animationName));
                  seq.start();
               }
            }
            return;
         }
         catch(e:Error)
         {
            return;
         }
      }
      
      [Trusted]
      public function playSpellAnimation(spellId:int, spellLevel:int, targetCellId:int) : void
      {
         var rpSpellCastProvider:RoleplaySpellCastProvider = new RoleplaySpellCastProvider();
         rpSpellCastProvider.castingSpell.casterId = PlayedCharacterManager.getInstance().id;
         rpSpellCastProvider.castingSpell.spell = Spell.getSpellById(spellId);
         rpSpellCastProvider.castingSpell.spellRank = rpSpellCastProvider.castingSpell.spell.getSpellLevel(spellLevel);
         rpSpellCastProvider.castingSpell.targetedCell = MapPoint.fromCellId(targetCellId);
         var spellScriptId:int = rpSpellCastProvider.castingSpell.spell.getScriptId(rpSpellCastProvider.castingSpell.isCriticalHit);
         SpellScriptManager.getInstance().runSpellScript(spellScriptId,rpSpellCastProvider,new Callback(this.executeSpellBuffer,null,true,true,rpSpellCastProvider),new Callback(this.executeSpellBuffer,null,true,false,rpSpellCastProvider));
      }
      
      [Untrusted]
      public function showNpcBubble(npcID:int, text:String) : void
      {
         var entitesBound:* = null;
         var npc:* = null;
         var entite:* = null;
         var bubble:* = null;
         var abstractEntitiesFrame:RoleplayEntitiesFrame = Kernel.getWorker().getFrame(RoleplayEntitiesFrame) as RoleplayEntitiesFrame;
         var list:Dictionary = abstractEntitiesFrame.getEntitiesDictionnary();
         if(list.length <= 0)
         {
            return;
         }
         for each(npc in list)
         {
            if(npc is GameRolePlayNpcInformations && npc.npcId == npcID)
            {
               entite = DofusEntities.getEntity(GameRolePlayNpcInformations(npc).contextualId) as IDisplayable;
               entitesBound = entite.absoluteBounds;
               bubble = new ChatBubble(text);
               TooltipManager.show(bubble,entitesBound,UiModuleManager.getInstance().getModule("Ankama_Tooltips"),true,"npcBubble" + npcID,LocationEnum.POINT_BOTTOMLEFT,LocationEnum.POINT_TOPRIGHT,0,true,null,null,null,null,false,StrataEnum.STRATA_WORLD);
               return;
            }
         }
      }
      
      [Untrusted]
      public function getMonsterXpBoostMultiplier(pMonsterId:int) : Number
      {
         return this.worldFrame.getMonsterXpBoostMultiplier(pMonsterId);
      }
      
      [Untrusted]
      public function getMonsterDropBoostMultiplier(pMonsterId:int) : Number
      {
         return this.worldFrame.getMonsterDropBoostMultiplier(pMonsterId);
      }
      
      [Untrusted]
      public function getRaceXpBoostMultiplier(pRaceId:int) : Number
      {
         return this.worldFrame.getRaceXpBoostMultiplier(pRaceId);
      }
      
      [Untrusted]
      public function getRaceDropBoostMultiplier(pRaceId:int) : Number
      {
         return this.worldFrame.getRaceDropBoostMultiplier(pRaceId);
      }
      
      [Untrusted]
      public function getMonsterGroupString(pMonsterGroupInfo:*) : String
      {
         var i:int = 0;
         var j:int = 0;
         var k:int = 0;
         var staticInfo:* = null;
         var staticInfoWithAlternative:* = null;
         var alternativeMaxLength:* = 0;
         var monsterInfo:* = null;
         var monsterId:* = 0;
         var monsterGrade:* = 0;
         var monsterGroupInfoString:* = "";
         monsterGroupInfoString = monsterGroupInfoString + (pMonsterGroupInfo.contextualId + ";");
         monsterGroupInfoString = monsterGroupInfoString + (pMonsterGroupInfo.creationTime + ";");
         monsterGroupInfoString = monsterGroupInfoString + (pMonsterGroupInfo.ageBonusRate + ";");
         monsterGroupInfoString = monsterGroupInfoString + ((!!pMonsterGroupInfo.hasOwnProperty("nbWaves")?pMonsterGroupInfo["nbWaves"]:0) + ";");
         var staticInfos:Array = new Array();
         staticInfos.push(pMonsterGroupInfo.staticInfos);
         if(pMonsterGroupInfo is GameRolePlayGroupMonsterWaveInformations)
         {
            for(i = 0; i < pMonsterGroupInfo.alternatives.length; i++)
            {
               staticInfos.push(pMonsterGroupInfo.alternatives[i]);
            }
         }
         var playerCount:String = "";
         for(i = 0; i < staticInfos.length; i++)
         {
            staticInfo = staticInfos[i];
            staticInfoWithAlternative = staticInfo as GroupMonsterStaticInformationsWithAlternatives;
            if(staticInfoWithAlternative)
            {
               alternativeMaxLength = 0;
               playerCount = "";
               for(j = 0; j < staticInfoWithAlternative.alternatives.length; j++)
               {
                  playerCount = playerCount + (staticInfoWithAlternative.alternatives[j].playerCount + ":");
                  alternativeMaxLength = uint(Math.max(alternativeMaxLength,staticInfoWithAlternative.alternatives[j].monsters.length));
               }
               monsterGroupInfoString = monsterGroupInfoString + ("@" + playerCount.substr(0,playerCount.length - 1) + "|");
               for(j = 0; j < alternativeMaxLength; j++)
               {
                  for(k = 0; k < staticInfoWithAlternative.alternatives.length; k++)
                  {
                     monsterInfo = j < staticInfoWithAlternative.alternatives[k].monsters.length?staticInfoWithAlternative.alternatives[k].monsters[j]:null;
                     if(monsterInfo)
                     {
                        monsterId = uint(monsterInfo.creatureGenericId);
                     }
                     monsterGrade = uint(!!monsterInfo?uint(monsterInfo.grade):uint(0));
                     monsterGroupInfoString = monsterGroupInfoString + (monsterGrade + ":");
                  }
                  monsterGroupInfoString = monsterGroupInfoString.substr(0,monsterGroupInfoString.length - 1) + "x" + monsterId + "|";
               }
               monsterGroupInfoString = monsterGroupInfoString.substr(0,monsterGroupInfoString.length - 1);
            }
            else
            {
               monsterGroupInfoString = monsterGroupInfoString + (staticInfo.mainCreatureLightInfos.grade + "x" + staticInfo.mainCreatureLightInfos.creatureGenericId);
               for(j = 0; j < staticInfo.underlings.length; j++)
               {
                  monsterGroupInfoString = monsterGroupInfoString + ("|" + staticInfo.underlings[j].grade + "x" + staticInfo.underlings[j].creatureGenericId);
               }
            }
            monsterGroupInfoString = monsterGroupInfoString + "&";
         }
         monsterGroupInfoString = monsterGroupInfoString.substr(0,monsterGroupInfoString.length - 1);
         return monsterGroupInfoString;
      }
      
      [Untrusted]
      public function getMonsterGroupFromString(pMonsterGroupString:String) : GameRolePlayGroupMonsterInformations
      {
         var monsterGroupInfos:* = null;
         var alternatives:* = null;
         var i:int = 0;
         var infos:Array = pMonsterGroupString.split(";");
         var creationTime:Number = infos[1];
         var ageBonusRate:uint = infos[2];
         var nbWaves:uint = infos[3];
         var groups:Array = infos[4].split("&");
         var mainCreatureStaticInfos:GroupMonsterStaticInformations = this.getMonsterStaticInfos(groups[0]);
         if(nbWaves > 0)
         {
            alternatives = new Vector.<GroupMonsterStaticInformations>();
            for(i = 1; i < groups.length; i++)
            {
               alternatives.push(this.getMonsterStaticInfos(groups[i]));
            }
            monsterGroupInfos = new GameRolePlayGroupMonsterWaveInformations();
            (monsterGroupInfos as GameRolePlayGroupMonsterWaveInformations).initGameRolePlayGroupMonsterWaveInformations(0,null,null,mainCreatureStaticInfos,creationTime,ageBonusRate,0,0,false,false,false,nbWaves,alternatives);
         }
         else
         {
            monsterGroupInfos = new GameRolePlayGroupMonsterInformations();
            monsterGroupInfos.initGameRolePlayGroupMonsterInformations(0,null,null,mainCreatureStaticInfos,creationTime,ageBonusRate);
         }
         monsterGroupInfos.disposition = new EntityDispositionInformations();
         monsterGroupInfos.disposition.initEntityDispositionInformations(-1);
         return monsterGroupInfos;
      }
      
      [Untrusted]
      public function getAlmanaxCalendar() : AlmanaxCalendar
      {
         return AlmanaxManager.getInstance().calendar;
      }
      
      [Untrusted]
      public function getAlmanaxMonsterXpBonusMultiplier(pMonsterId:int) : Number
      {
         var bonusId:int = 0;
         var bonus:* = null;
         var mul:* = Number(NaN);
         for each(bonusId in AlmanaxManager.getInstance().calendar.bonusesIds)
         {
            bonus = Bonus.getBonusById(bonusId);
            if(bonus is MonsterXPBonus && (bonus.isRespected(pMonsterId) || bonus.isRespected(Monster.getMonsterById(pMonsterId).race)))
            {
               if(isNaN(mul))
               {
                  mul = 1;
               }
               mul = Number(mul * (bonus.amount / 100));
            }
         }
         return 1 + (!!isNaN(mul)?0:mul);
      }
      
      [Untrusted]
      public function getAlmanaxMonsterDropChanceBonusMultiplier(pMonsterId:int) : Number
      {
         var bonusId:int = 0;
         var bonus:* = null;
         var mul:* = Number(NaN);
         for each(bonusId in AlmanaxManager.getInstance().calendar.bonusesIds)
         {
            bonus = Bonus.getBonusById(bonusId);
            if(bonus is MonsterDropChanceBonus && (bonus.isRespected(pMonsterId) || bonus.isRespected(Monster.getMonsterById(pMonsterId).race)))
            {
               if(isNaN(mul))
               {
                  mul = 1;
               }
               mul = Number(mul * (bonus.amount / 100));
            }
         }
         return 1 + (!!isNaN(mul)?0:mul);
      }
      
      [Untrusted]
      public function getAlmanaxMonsterStarRateBonus() : int
      {
         var bonusId:int = 0;
         var bonus:* = null;
         for each(bonusId in AlmanaxManager.getInstance().calendar.bonusesIds)
         {
            bonus = Bonus.getBonusById(bonusId);
            if(bonus is MonsterStarRateBonus && bonus.isRespected())
            {
               return bonus.amount;
            }
         }
         return 0;
      }
      
      [Untrusted]
      public function isMonsterAttacking(pMonsterId:int, pGrade:int) : Boolean
      {
         var mapPos:MapPosition = !!PlayedCharacterManager.getInstance().currentMap?MapPosition.getMapPositionById(PlayedCharacterManager.getInstance().currentMap.mapId):null;
         if(mapPos && _mapApi.isDungeonSubArea(mapPos.subArea.id) != -1)
         {
            return false;
         }
         if(mapPos && !mapPos.allowMonsterAggression)
         {
            return false;
         }
         if(!PlayedCharacterManager.getInstance().canBeAggressedByMonsters)
         {
            return false;
         }
         var monster:Monster = Monster.getMonsterById(pMonsterId);
         if(!monster.isAggressive)
         {
            return false;
         }
         if(!monster.canAttack)
         {
            return false;
         }
         if(monster.getAggressionLevel(pGrade) < Math.min(PlayedCharacterManager.getInstance().infos.level,ProtocolConstantsEnum.MAX_LEVEL))
         {
            return false;
         }
         return true;
      }
      
      [Untrusted]
      public function isMonstersGroupAttacking(pMonstersInfo:GroupMonsterStaticInformations) : Boolean
      {
         var monsterInfo:* = null;
         var aggressionLevel:int = 0;
         var underling:* = null;
         var leaderLevelDifference:int = 0;
         var mapPos:MapPosition = !!PlayedCharacterManager.getInstance().currentMap?MapPosition.getMapPositionById(PlayedCharacterManager.getInstance().currentMap.mapId):null;
         if(mapPos && _mapApi.isDungeonSubArea(mapPos.subArea.id) != -1)
         {
            return false;
         }
         if(mapPos && !mapPos.allowMonsterAggression)
         {
            return false;
         }
         if(!PlayedCharacterManager.getInstance().canBeAggressedByMonsters)
         {
            return false;
         }
         var leader:Monster = Monster.getMonsterById(pMonstersInfo.mainCreatureLightInfos.creatureGenericId);
         if(!leader.canAttack)
         {
            return false;
         }
         var maxLevel:int = leader.grades[pMonstersInfo.mainCreatureLightInfos.grade - 1].level;
         var maxAggressiveZone:int = leader.aggressiveZoneSize;
         var leaderAggressionLevel:int = leader.getAggressionLevel(pMonstersInfo.mainCreatureLightInfos.grade);
         var maxAggressionLevel:int = leaderAggressionLevel;
         for each(monsterInfo in pMonstersInfo.underlings)
         {
            underling = Monster.getMonsterById(monsterInfo.creatureGenericId);
            if(underling.isAggressive)
            {
               maxLevel = Math.max(underling.grades[monsterInfo.grade - 1].level,maxLevel);
               maxAggressiveZone = Math.max(underling.aggressiveZoneSize,maxAggressiveZone);
               maxAggressionLevel = Math.max(underling.getAggressionLevel(monsterInfo.grade),maxAggressionLevel);
            }
         }
         if(maxAggressiveZone == 0)
         {
            return false;
         }
         if(maxAggressionLevel == leaderAggressionLevel)
         {
            aggressionLevel = leaderAggressionLevel;
         }
         else
         {
            leaderLevelDifference = !!leader.useRaceValues?int(MonsterRace.getMonsterRaceById(leader.race).aggressiveLevelDiff):int(leader.aggressiveLevelDiff);
            aggressionLevel = maxLevel - (leaderLevelDifference + leaderAggressionLevel - maxAggressionLevel);
         }
         return Math.min(PlayedCharacterManager.getInstance().infos.level,ProtocolConstantsEnum.MAX_LEVEL) < aggressionLevel;
      }
      
      private function getMonsterStaticInfos(pMonsterGroupString:String) : GroupMonsterStaticInformations
      {
         var monsterStaticInfo:* = null;
         var monsters:* = null;
         var underlings:* = null;
         var i:int = 0;
         var j:int = 0;
         var playerCounts:* = null;
         var monsterStr:* = null;
         var alternatives:* = null;
         var alternative:* = null;
         var alternativeMonsters:* = null;
         var alternativeMonsterInfo:* = null;
         var alternativeMonsterSplit:* = null;
         var alternativeMonsterGrades:* = null;
         var monsterStaticInfoWithAlternative:* = null;
         if(pMonsterGroupString.charAt(0) == "@")
         {
            pMonsterGroupString = pMonsterGroupString.substr(1);
            monsters = pMonsterGroupString.split("|");
            playerCounts = monsters[0].split(":");
            monsters.shift();
            if(monsters.length > 1)
            {
               underlings = new Vector.<MonsterInGroupInformations>();
               for(i = 1; i < monsters.length; i++)
               {
                  monsterStr = monsters[i].substr(monsters[i].lastIndexOf(":") + 1);
                  underlings.push(this.getMonsterInGroupInfo(monsterStr));
               }
            }
            alternatives = new Vector.<AlternativeMonstersInGroupLightInformations>();
            for(i = 0; i < playerCounts.length; i++)
            {
               alternative = new AlternativeMonstersInGroupLightInformations();
               alternativeMonsters = new Vector.<MonsterInGroupLightInformations>();
               for(j = 0; j < monsters.length; )
               {
                  alternativeMonsterSplit = monsters[j].split("x");
                  alternativeMonsterGrades = alternativeMonsterSplit[0].split(":");
                  if(alternativeMonsterGrades[i] > 0)
                  {
                     alternativeMonsterInfo = new MonsterInGroupLightInformations();
                     alternativeMonsterInfo.initMonsterInGroupLightInformations(alternativeMonsterSplit[1],alternativeMonsterGrades[i]);
                     alternativeMonsters.push(alternativeMonsterInfo);
                  }
                  j++;
               }
               alternative.initAlternativeMonstersInGroupLightInformations(playerCounts[i],alternativeMonsters);
               alternatives.push(alternative);
            }
            monsterStaticInfoWithAlternative = new GroupMonsterStaticInformationsWithAlternatives();
            monsterStaticInfoWithAlternative.initGroupMonsterStaticInformationsWithAlternatives(this.getMonsterInGroupInfo(monsters[0].substr(monsters[0].lastIndexOf(":") + 1)),underlings,alternatives);
            monsterStaticInfo = monsterStaticInfoWithAlternative;
         }
         else
         {
            monsters = pMonsterGroupString.split("|");
            monsterStaticInfo = new GroupMonsterStaticInformations();
            if(monsters.length > 1)
            {
               underlings = new Vector.<MonsterInGroupInformations>();
               for(i = 1; i < monsters.length; i++)
               {
                  underlings.push(this.getMonsterInGroupInfo(monsters[i]));
               }
            }
            monsterStaticInfo.initGroupMonsterStaticInformations(this.getMonsterInGroupInfo(monsters[0]),underlings);
         }
         return monsterStaticInfo;
      }
      
      private function getMonsterInGroupInfo(pMonster:String) : MonsterInGroupInformations
      {
         var monsterInfos:Array = pMonster.split("x");
         var infos:MonsterInGroupInformations = new MonsterInGroupInformations();
         infos.initMonsterInGroupInformations(monsterInfos[1],monsterInfos[0]);
         return infos;
      }
      
      private function executeSpellBuffer(callback:Function, hadScript:Boolean, scriptSuccess:Boolean = false, castProvider:RoleplaySpellCastProvider = null) : void
      {
         var step:* = null;
         var ss:SerialSequencer = new SerialSequencer();
         for each(step in castProvider.stepsBuffer)
         {
            ss.addStep(step);
         }
         ss.start();
      }
   }
}
