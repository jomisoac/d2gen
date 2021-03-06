package com.ankamagames.dofus.logic.game.common.frames
{
   import com.ankamagames.berilia.managers.KernelEventsManager;
   import com.ankamagames.dofus.internalDatacenter.items.ItemWrapper;
   import com.ankamagames.dofus.internalDatacenter.items.TradeStockItemWrapper;
   import com.ankamagames.dofus.kernel.Kernel;
   import com.ankamagames.dofus.kernel.net.ConnectionsHandler;
   import com.ankamagames.dofus.logic.game.common.actions.exchange.ExchangeObjectModifyPricedAction;
   import com.ankamagames.dofus.logic.game.common.managers.EntitiesLooksManager;
   import com.ankamagames.dofus.logic.game.common.managers.PlayedCharacterManager;
   import com.ankamagames.dofus.logic.game.roleplay.actions.LeaveDialogRequestAction;
   import com.ankamagames.dofus.logic.game.roleplay.frames.RoleplayContextFrame;
   import com.ankamagames.dofus.misc.lists.ExchangeHookList;
   import com.ankamagames.dofus.network.enums.DialogTypeEnum;
   import com.ankamagames.dofus.network.messages.game.dialog.LeaveDialogRequestMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeLeaveMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeObjectModifyPricedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeShopStockMovementRemovedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeShopStockMovementUpdatedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeShopStockMultiMovementRemovedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeShopStockMultiMovementUpdatedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeShopStockStartedMessage;
   import com.ankamagames.dofus.network.messages.game.inventory.exchanges.ExchangeStartOkHumanVendorMessage;
   import com.ankamagames.dofus.network.types.game.context.roleplay.GameRolePlayMerchantInformations;
   import com.ankamagames.dofus.network.types.game.data.items.ObjectItemToSell;
   import com.ankamagames.dofus.network.types.game.data.items.ObjectItemToSellInHumanVendorShop;
   import com.ankamagames.jerakine.logger.Log;
   import com.ankamagames.jerakine.logger.Logger;
   import com.ankamagames.jerakine.messages.Frame;
   import com.ankamagames.jerakine.messages.Message;
   import com.ankamagames.jerakine.types.enums.Priority;
   import flash.utils.getQualifiedClassName;
   
   public class HumanVendorManagementFrame implements Frame
   {
      
      protected static const _log:Logger = Log.getLogger(getQualifiedClassName(HumanVendorManagementFrame));
       
      
      private var _success:Boolean = false;
      
      private var _shopStock:Array;
      
      public function HumanVendorManagementFrame()
      {
         super();
         this._shopStock = new Array();
      }
      
      public function get priority() : int
      {
         return Priority.NORMAL;
      }
      
      private function get roleplayContextFrame() : RoleplayContextFrame
      {
         return Kernel.getWorker().getFrame(RoleplayContextFrame) as RoleplayContextFrame;
      }
      
      private function get commonExchangeManagementFrame() : CommonExchangeManagementFrame
      {
         return Kernel.getWorker().getFrame(CommonExchangeManagementFrame) as CommonExchangeManagementFrame;
      }
      
      public function pushed() : Boolean
      {
         this._success = false;
         return true;
      }
      
      public function process(msg:Message) : Boolean
      {
         var stockItem:* = null;
         var esohvmsg:* = null;
         var player:* = undefined;
         var playerName:* = null;
         var esostmsg:* = null;
         var eompa:* = null;
         var eomfpmsg:* = null;
         var essmamsg:* = null;
         var itemWrapper:* = null;
         var newPrice:Number = NaN;
         var newItem:Boolean = false;
         var essmrmsg:* = null;
         var essmmumsg:* = null;
         var essmmrmsg:* = null;
         var elm:* = null;
         var objectToSell:* = null;
         var object:* = null;
         var i:int = 0;
         var objectInfo:* = null;
         var newItem2:Boolean = false;
         var objectId:int = 0;
         switch(true)
         {
            case msg is ExchangeStartOkHumanVendorMessage:
               esohvmsg = msg as ExchangeStartOkHumanVendorMessage;
               player = this.roleplayContextFrame.entitiesFrame.getEntityInfos(esohvmsg.sellerId);
               PlayedCharacterManager.getInstance().isInExchange = true;
               if(player == null)
               {
                  _log.error("Impossible de trouver le personnage vendeur dans l\'entitiesFrame");
                  return true;
               }
               playerName = (player as GameRolePlayMerchantInformations).name;
               this._shopStock = new Array();
               for each(objectToSell in esohvmsg.objectsInfos)
               {
                  stockItem = TradeStockItemWrapper.createFromObjectItemToSell(objectToSell);
                  this._shopStock.push(stockItem);
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeStartOkHumanVendor,playerName,this._shopStock,EntitiesLooksManager.getInstance().getTiphonEntityLook(esohvmsg.sellerId));
               return true;
            case msg is ExchangeShopStockStartedMessage:
               esostmsg = msg as ExchangeShopStockStartedMessage;
               PlayedCharacterManager.getInstance().isInExchange = true;
               this._shopStock = new Array();
               for each(object in esostmsg.objectsInfos)
               {
                  stockItem = TradeStockItemWrapper.createFromObjectItemToSell(object);
                  _log.debug(" - " + stockItem.itemWrapper.name);
                  this._shopStock.push(stockItem);
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockStarted,this._shopStock);
               return true;
            case msg is ExchangeObjectModifyPricedAction:
               eompa = msg as ExchangeObjectModifyPricedAction;
               eomfpmsg = new ExchangeObjectModifyPricedMessage();
               eomfpmsg.initExchangeObjectModifyPricedMessage(eompa.objectUID,eompa.quantity,eompa.price);
               ConnectionsHandler.getConnection().send(eomfpmsg);
               return true;
            case msg is ExchangeShopStockMovementUpdatedMessage:
               essmamsg = msg as ExchangeShopStockMovementUpdatedMessage;
               itemWrapper = ItemWrapper.create(0,essmamsg.objectInfo.objectUID,essmamsg.objectInfo.objectGID,essmamsg.objectInfo.quantity,essmamsg.objectInfo.effects,false);
               newPrice = essmamsg.objectInfo.objectPrice;
               newItem = true;
               for(i = 0; i < this._shopStock.length; )
               {
                  if(this._shopStock[i].itemWrapper.objectUID == itemWrapper.objectUID)
                  {
                     if(itemWrapper.quantity > this._shopStock[i].itemWrapper.quantity)
                     {
                        KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockAddQuantity);
                     }
                     else
                     {
                        KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockRemoveQuantity);
                     }
                     stockItem = TradeStockItemWrapper.create(itemWrapper,newPrice);
                     this._shopStock.splice(i,1,stockItem);
                     newItem = false;
                     break;
                  }
                  i++;
               }
               if(newItem)
               {
                  stockItem = TradeStockItemWrapper.create(itemWrapper,essmamsg.objectInfo.objectPrice);
                  this._shopStock.push(stockItem);
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockUpdate,this._shopStock,itemWrapper);
               return true;
            case msg is ExchangeShopStockMovementRemovedMessage:
               essmrmsg = msg as ExchangeShopStockMovementRemovedMessage;
               for(i = 0; i < this._shopStock.length; )
               {
                  if(this._shopStock[i].itemWrapper.objectUID == essmrmsg.objectId)
                  {
                     this._shopStock.splice(i,1);
                     break;
                  }
                  i++;
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockUpdate,this._shopStock,null);
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockMovementRemoved,essmrmsg.objectId);
               return true;
            case msg is ExchangeShopStockMultiMovementUpdatedMessage:
               essmmumsg = msg as ExchangeShopStockMultiMovementUpdatedMessage;
               for each(objectInfo in essmmumsg.objectInfoList)
               {
                  itemWrapper = ItemWrapper.create(0,objectInfo.objectUID,essmamsg.objectInfo.objectGID,objectInfo.quantity,objectInfo.effects,false);
                  newItem2 = true;
                  for(i = 0; i < this._shopStock.length; )
                  {
                     if(this._shopStock[i].itemWrapper.objectUID == itemWrapper.objectUID)
                     {
                        stockItem = TradeStockItemWrapper.create(itemWrapper,essmamsg.objectInfo.objectPrice);
                        this._shopStock.splice(i,1,stockItem);
                        newItem2 = false;
                        break;
                     }
                     i++;
                  }
                  if(newItem2)
                  {
                     stockItem = TradeStockItemWrapper.create(itemWrapper,essmamsg.objectInfo.objectPrice);
                     this._shopStock.push(stockItem);
                  }
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockUpdate,this._shopStock);
               return true;
            case msg is ExchangeShopStockMultiMovementRemovedMessage:
               essmmrmsg = msg as ExchangeShopStockMultiMovementRemovedMessage;
               loop6:
               for each(objectId in essmmrmsg.objectIdList)
               {
                  for(i = 0; i < this._shopStock.length; )
                  {
                     if(this._shopStock[i].itemWrapper.objectUID == objectId)
                     {
                        this._shopStock.splice(i,1);
                        continue loop6;
                     }
                     i++;
                  }
               }
               KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeShopStockMouvmentRemoveOk,essmrmsg.objectId);
               return true;
            case msg is LeaveDialogRequestAction:
               ConnectionsHandler.getConnection().send(new LeaveDialogRequestMessage());
               return true;
            case msg is ExchangeLeaveMessage:
               elm = msg as ExchangeLeaveMessage;
               if(elm.dialogType == DialogTypeEnum.DIALOG_EXCHANGE)
               {
                  PlayedCharacterManager.getInstance().isInExchange = false;
                  this._success = elm.success;
                  Kernel.getWorker().removeFrame(this);
               }
               return true;
            default:
               return false;
         }
      }
      
      public function pulled() : Boolean
      {
         if(Kernel.getWorker().contains(CommonExchangeManagementFrame))
         {
            Kernel.getWorker().removeFrame(Kernel.getWorker().getFrame(CommonExchangeManagementFrame));
         }
         KernelEventsManager.getInstance().processCallback(ExchangeHookList.ExchangeLeave,this._success);
         this._shopStock = null;
         return true;
      }
   }
}
