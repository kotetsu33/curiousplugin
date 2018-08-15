# coding=utf-8
from __future__ import absolute_import

import os
import subprocess
import datetime
import octoprint.plugin

from octoprint.events import Events


class CuriousPlugin(octoprint.plugin.StartupPlugin,
                    octoprint.plugin.EventHandlerPlugin):

    def __init__(self):
        self._start_tm  = None
        self._file_nm   = None
        self._exec_path = None

        self._arec_pid  = None

    def _set_params(self):
        dt_now = datetime.datetime.now()

        self._start_tm = dt_now.strftime('%Y%m%d %H:%M:%S')
        self._file_nm  = dt_now.strftime('%Y%m%d_%H%M%S_%f')

    def on_after_startup(self):
        self._logger.info("Curious plugin started.")
        self._logger.info(os.path.dirname(os.path.abspath(__file__)))
        self._exec_path = os.path.dirname(os.path.abspath(__file__))

    def on_event(self, event, payload):

        if event == Events.PRINT_STARTED:

            self._set_params()
            cmd = ['/bin/bash', self._exec_path + '/arecord.sh', '-c', '1', '-r', '44100', '-f', 'S16_LE', '-D', 'plughw:1,0', self._exec_path + '/' + self._file_nm + '.wav']
            proc = subprocess.Popen(cmd,shell=False)
            proc.wait()
            if proc.returncode != 0:
                self._logger.error("Curious plugin : arecord start faild.")

            self._logger.info("Curious plugin : recording started...")
            self._arec_pid = proc.pid

        if event == Events.PRINT_DONE or event == Events.PRINT_CANCELLED:

            cmd = 'ps axuww | grep arecor[d] | awk \'{print $2}\' | xargs kill -15'
            proc = subprocess.Popen(cmd, shell=True)
            proc.wait()
            if proc.returncode != 0:
                self._logger.error("Curious plugin : arecord stop faild.")

            self._logger.info("Curious plugin : recording finishd.")
            cmd = ['/bin/bash', self._exec_path + '/audio_set.sh', '\"' + self._start_tm + '\"', self._file_nm + '.wav']
            proc = subprocess.Popen(cmd,shell=False)
            proc.wait()
            self._logger.info("Curious plugin : upload finishd.")
            if proc.returncode != 0:
                self._logger.error("Curious plugin : split and upload faild.")


__plugin_implementation__ = CuriousPlugin()

