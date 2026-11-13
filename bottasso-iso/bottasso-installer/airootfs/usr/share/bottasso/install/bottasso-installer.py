#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
BOTASSO OS Installer -- interfaz grafica de la live ISO.

Se lanza automaticamente despues del login KDE (autostart), o manualmente
desde el escritorio KDE.

El motor real (particionado, pacstrap, grub, rebrand) se ejecuta fuera de la
interfaz v[ia] instalador.sh, que imprime lineas prefijadas para que esta
interfaz las lea desde su tubo de salida (QProcess).
"""

import os
import sys
import subprocess
import time

from PyQt6.QtCore import QThread, pyqtSignal, QProcess, Qt, QTimer
from PyQt6.QtGui import QPalette, QColor
from PyQt6.QtWidgets import (
    QApplication, QWizard, QWizardPage, QLabel, QProgressBar,
    QTextEdit, QPushButton, QVBoxLayout, QHBoxLayout, QComboBox,
    QListWidget, QListWidgetItem, QMessageBox, QStyle,
)

APP_TITLE = "BOTASSO OS Installador"
BASE = "/usr/share/bottasso/install"
SCRIPT = os.path.join(BASE, "install-bottasso.sh")
DISKS_FILE = "/proc/partitions"


# ---------------------------------------------------------------------------
# Deteccion de discos
# ---------------------------------------------------------------------------
def detect_disks():
    disks = []
    if not os.path.exists(DISKS_FILE):
        return disks
    try:
        with open(DISKS_FILE, "r", encoding="utf-8", errors="replace") as fh:
            lines = fh.readlines()
    except OSError:
        return disks
    for ln in lines[2:]:
        parts = ln.split()
        if len(parts) < 4:
            continue
        try:
            maj, min_ = int(parts[0]), int(parts[1])
        except ValueError:
            continue
        if maj == 0 or min_ == 0:
            continue
        size = ""
        blk = "/sys/block/" + parts[2]
        if os.path.isdir(blk):
            dev = os.path.join(blk, "dev")
            if os.path.exists(dev):
                try:
                    with open(dev, "r") as df:
                        size = df.read().strip()
                except OSError:
                    pass
        disks.append({"name": parts[2], "size": size, "major": maj, "minor": min_})
    return disks


# ---------------------------------------------------------------------------
# Motor del instalador (en un hilo paralelo)
# ---------------------------------------------------------------------------
class InstallerEngine(QThread):
    progress = pyqtSignal(int)
    message = pyqtSignal(str)
    error = pyqtSignal(str)
    log = pyqtSignal(str)
    finished = pyqtSignal(int)

    def __init__(self, script, disk, mode):
        super().__init__()
        self.script = script
        self.disk = disk
        self.mode = mode

    def run(self):
        self._proc = QProcess()
        self._proc.setProcessChannelMode(QProcess.ProcessChannelMode.Separate)
        self._proc.readyReadStandardOutput.connect(self._on_stdout)
        self._proc.readyReadStandardError.connect(self._on_stderr)
        self._proc.finished.connect(self._on_finished)

        if not self._proc.start(self.script,
                                [f"--disk={self.disk}",
                                 f"--mode={self.mode}", "--yes"]):
            self.error.emit("No se pudo iniciar el instalador.")
            self.finished.emit(-1)
            return
        if not self._proc.waitForStarted(15000):
            self.error.emit("No responde el instalador.")
            self.finished.emit(-1)
            return
        self._proc.waitForFinished(-1)
        self.exit_code = self._proc.exitCode()

    def _on_stdout(self):
        data = self._proc.readAllStandardOutput()
        txt = bytes(data).decode("utf-8", "replace")
        self._rb += txt
        while "\n" in self._rb:
            line, self._rb = self._rb.split("\n", 1)
            self._emit(line)

    def _on_stderr(self):
        data = self._proc.readAllStandardError()
        txt = bytes(data).decode("utf-8", "replace")
        self._rb += txt
        while "\n" in self._rb:
            line, self._rb = self._rb.split("\n", 1)
            self._emit(line)

    def _emit(self, line):
        line = line.rstrip("\r")
        if line.startswith("[PB]"):
            try:
                self.progress.emit(int(line[4:].strip()))
            except ValueError:
                pass
        elif line.startswith("[MB]"):
            self.message.emit(line[4:])
        elif line.startswith("[ERRO]"):
            self.error.emit(line[6:])
        elif line.startswith("[LOG]"):
            self.log.emit(line[5:])


# ---------------------------------------------------------------------------
# Paginas del instalador
# ---------------------------------------------------------------------------
class PageWelcome(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Bienvenido")
        self.setSubTitle("Instalador grafico de BOTASSO OS")
        lay = QVBoxLayout()
        lay.addWidget(QLabel(
            "<h1 style='color:#4582DC'>BOTASSO OS</h1>"
            "<p>Distribucion Linux personalizada sobre <b>CachyOS</b> "
            "con <b>KDE Plasma 6</b>.</p>"
            "<p>Recupera tu disco y entra a <code>BOTASSO OS</code> en "
            "menos de un minuto.</p>"
        ))
        lay.addWidget(QLabel("<b>Paso 1/5</b> de configuracion"))
        lay.addStretch()
        lay.addWidget(QPushButton("Siguiente", self))
        self.setLayout(lay)


class PageInfo(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Informacion del sistema")
        self.setSubTitle("Configuracion detectada")
        lay = QVBoxLayout()
        self.info = QTextEdit()
        self.info.setReadOnly(True)
        self.info.setMaximumHeight(110)
        self.info.setStyleSheet(
            "background:#0f0f1a;color:#fff;font-size:12px;")
        lay.addWidget(self.info)
        lay.addWidget(QPushButton("Siguiente", self))
        self.setLayout(lay)

    def initPage(self):
        self.info.clear()
        txt = "Discos detectados:\n"
        for d in detect_disks():
            txt += f"  - {d['name']}  ({d['size']})\n"
        txt += "\nIdioma: es_CL.UTF-8\nZona horaria: America/Santiago\n"
        self.info.setPlainText(txt)


class PageDisk(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Disco de destino")
        self.setSubTitle("Selecciona el disco y el modo de instalacion")
        lay = QVBoxLayout()
        self.mode = QComboBox()
        self.mode.addItems(["Borrar y instalar",
                            "Duable con Windows", "Particion manual"])
        self.mode.setCurrentIndex(0)
        lay.addWidget(QLabel("Modo de instalacion:"))
        lay.addWidget(self.mode)
        self.list = QListWidget()
        self.list.setAlternatingRowColors(True)
        self.list.setStyleSheet("background:#0f0f1a;color:#fff;")
        lay.addWidget(QLabel("Discos disponibles:"))
        lay.addWidget(self.list)
        lay.addWidget(QPushButton("Siguiente", self))
        self.setLayout(lay)

    def initPage(self):
        self.list.clear()
        disks = detect_disks()
        if not disks:
            QMessageBox.information(self, "Sin discos",
                                    "No se detectaron discos.")
            self.wizard().button(QWizard.Button.Next).setDisabled(True)
            return
        for d in disks:
            self.list.addItem(QListWidgetItem(
                f"{d['name']}  ({d['size']})"))

    def nextId(self):
        if self.list.count() == 0:
            return -1
        return QWizard.PageButton.Next


class PageInstall(QWizardPage):
    def __init__(self, disk, mode):
        super().__init__()
        self.setTitle("Instalando")
        self.setSubTitle("Por favor, no apagues el ordenador.")
        lay = QVBoxLayout()
        self.progress = QProgressBar()
        self.progress.setValue(0)
        lay.addWidget(self.progress)
        self.msg = QLabel("Preparando...")
        self.msg.setStyleSheet("color:#fff;")
        lay.addWidget(self.msg)
        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(110)
        self.log.setStyleSheet("background:#0f0f1a;color:#888;font-size:12px;")
        lay.addWidget(self.log)
        self.cancel = QPushButton("Cancelar")
        self.cancel.clicked.connect(self._on_cancel)
        lay.addWidget(self.cancel)
        self.setLayout(lay)

        self.disk = disk
        self.mode = mode
        self.engine = None
        self.engine_signal = InstallerEngine(SCRIPT, disk, mode)
        self.engine_signal.progress.connect(self.progress.setValue)
        self.engine_signal.message.connect(self.msg.setText)
        self.engine_signal.error.connect(self._on_error)
        self.engine_signal.log.connect(self.log.append)
        self.engine_signal.finished.connect(self._on_finished)
        self._started = False

    def _on_cancel(self):
        if self.engine is not None and self.engine.isRunning():
            self.engine.terminate()
        self.wizard().setVisible(False)

    def _on_error(self, txt):
        self.log.append("ERR: " + txt)
        self.msg.setText("<b><font color=#ff5555>Error: " + txt + "</font></b>")

    def nextId(self):
        if not self._started:
            self._started = True
            self._start_engine()
        return QWizard.PageButton.Finish

    def _start_engine(self):
        self.log.clear()
        self.progress.setValue(0)
        self.msg.setText("Ejecutando instalador...")
        self.engine = InstallerEngine(SCRIPT, self.disk, self.mode)
        self.engine.progress.connect(self.progress.setValue)
        self.engine.message.connect(self.msg.setText)
        self.engine.error.connect(self._on_error)
        self.engine.log.connect(self.log.append)
        self.engine.finished.connect(self._on_finished)
        self.engine.start()

    def _on_finished(self, rc):
        if rc == 0:
            self.msg.setText("<b><font color=#55aa55>Instalacion "
                             "completada.</font></b>")
            self.log.append(">>> Instalacion terminada correctamente.")
            QTimer.singleShot(5000, self._final_reboot)
        else:
            self.msg.setText("<b><font color=#ff5555>Termino con "
                             "fallo.</font></b>")
            self.log.append(">>> Instalacion fallida (exit code %d)"
                            % rc)

    def _final_reboot(self):
        subprocess.Popen(["reboot"])


# ---------------------------------------------------------------------------
def main():
    app = QApplication(sys.argv)
    app.setApplicationName(APP_TITLE)
    app.setOrganizationName("BOTASSO")
    app.setStyle("Fusion")
    pal = QPalette()
    d = QColor("#1a1a2e"); l = QColor("#2a2a3e"); m = QColor("#1a1a2e")
    b = QColor("#121222")
    pal.setColor(QPalette.ColorRole.Window, d)
    pal.setColor(QPalette.ColorRole.WindowText, QColor("#ffffff"))
    pal.setColor(QPalette.ColorRole.Base, QColor("#12121f"))
    pal.setColor(QPalette.ColorRole.AlternateBase, d)
    pal.setColor(QPalette.ColorRole.Text, QColor("#ffffff"))
    pal.setColor(QPalette.ColorRole.Button, d)
    pal.setColor(QPalette.ColorRole.ButtonText, QColor("#ffffff"))
    pal.setColor(QPalette.ColorRole.Highlight, QColor("#4582DC"))
    pal.setColor(QPalette.ColorRole.HighlightedText, QColor("#ffffff"))
    pal.setColor(QPalette.ColorRole.Light, l)
    pal.setColor(QPalette.ColorRole.Midlight, l)
    pal.setColor(QPalette.ColorRole.Mid, m)
    pal.setColor(QPalette.ColorRole.Dark, b)
    pal.setColor(QPalette.ColorRole.Shadow, QColor("#000000"))
    app.setPalette(pal)

    wizard = QWizard()
    wizard.setWindowTitle(APP_TITLE)
    wizard.addPage(PageWelcome())
    page_info = PageInfo()
    wizard.addPage(page_info)
    page_disk = PageDisk()
    wizard.addPage(page_disk)
    wizard.addPage(PageInstall("", "erase"))

    w = wizard
    w.resize(680, 480)
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
