<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class Rol extends Migration
{

    public function up()
    {
        Schema::create('rol', function (Blueprint $table) {
            $table->id('idRol');
            $table->string('nombre');

        });
    }

  
    public function down()
    {
        Schema::dropIfExists('rol');
    }
}
