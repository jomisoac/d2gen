package com.ankama.codegen.client.model
{
   public class LadderModelFPioneerMonster
   {
       
      
      public var id:Number = 0;
      
      public var server:Number = 0;
      
      public var pioneers:Array;
      
      public var completionTime:Number = 0;
      
      public function LadderModelFPioneerMonster()
      {
         this.pioneers = new Array();
         super();
      }
      
      public function toString() : String
      {
         var sb:String = "";
         sb.concat("class LadderModelFPioneerMonster {\n");
         sb.concat("  id: ").concat(this.id).concat("\n");
         sb.concat("  server: ").concat(this.server).concat("\n");
         sb.concat("  pioneers: ").concat(this.pioneers).concat("\n");
         sb.concat("  completionTime: ").concat(this.completionTime).concat("\n");
         sb.concat("}\n");
         return sb;
      }
   }
}
