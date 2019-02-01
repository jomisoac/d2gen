package com.ankamagames.dofus.datacenter.items.criterion
{
   import com.ankamagames.dofus.datacenter.world.SubArea;
   import com.ankamagames.dofus.logic.game.common.managers.PlayedCharacterManager;
   import com.ankamagames.jerakine.data.I18n;
   import com.ankamagames.jerakine.interfaces.IDataCenter;
   
   public class SubareaItemCriterion extends ItemCriterion implements IDataCenter
   {
       
      
      public function SubareaItemCriterion(pCriterion:String)
      {
         super(pCriterion);
      }
      
      override public function get isRespected() : Boolean
      {
         var playerPosition:uint = PlayedCharacterManager.getInstance().currentSubArea.id;
         switch(_operator.text)
         {
            case ItemCriterionOperator.EQUAL:
            case ItemCriterionOperator.DIFFERENT:
               return super.isRespected;
            default:
               return false;
         }
      }
      
      override public function get text() : String
      {
         var readableCriterion:* = null;
         var subArea:SubArea = SubArea.getSubAreaById(_criterionValue);
         if(!subArea)
         {
            return "error on subareaItemCriterion";
         }
         var zoneName:String = subArea.name;
         switch(_operator.text)
         {
            case ItemCriterionOperator.EQUAL:
               readableCriterion = I18n.getUiText("ui.tooltip.beInSubarea",[zoneName]);
               break;
            case ItemCriterionOperator.DIFFERENT:
               readableCriterion = I18n.getUiText("ui.tooltip.dontBeInSubarea",[zoneName]);
         }
         return readableCriterion;
      }
      
      override public function clone() : IItemCriterion
      {
         var clonedCriterion:SubareaItemCriterion = new SubareaItemCriterion(this.basicText);
         return clonedCriterion;
      }
      
      override protected function getCriterion() : int
      {
         return PlayedCharacterManager.getInstance().currentSubArea.id;
      }
   }
}